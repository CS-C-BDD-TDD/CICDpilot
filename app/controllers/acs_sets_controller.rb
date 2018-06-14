class AcsSetsController < ApplicationController
  
  def index
    if params[:organization_guid]
      org = Organization.find_by_guid(params[:organization_guid])

      if org.present?
        @acs_sets = AcsSet.for_org(org).to_a.uniq
      else
        render json: {errors: [organization: "Could not find your organization"]}
      end
    elsif params[:id]
      @acs_sets = AcsSet.includes(
        stix_markings: [
            :isa_marking_structure,
            :tlp_marking_structure,
            {isa_assertion_structure: [:isa_privs,:further_sharings]}
        ]).find_by_guid(params[:id])

      if @acs_sets.blank?
        @acs_sets = AcsSet.includes(
          stix_markings: [
              :isa_marking_structure,
              :tlp_marking_structure,
              {isa_assertion_structure: [:isa_privs,:further_sharings]}
          ]).find_by_id(params[:id])
      end
    else
      @acs_sets = AcsSet.all
    end

    render json: @acs_sets
  end

   def show
    @acs_set = AcsSet.includes(:indicators, :course_of_actions, :threat_actors, :ttps, :exploit_targets, :stix_packages,
        stix_markings: [
            :isa_marking_structure,
            :tlp_marking_structure,
            :simple_marking_structure,
            {isa_assertion_structure: [:isa_privs,:further_sharings]}
        ]).find_by_guid(params[:id])

    if @acs_set.present?
      render json: @acs_set
    else
      render json: {errors: ['Unable to find ACS Set'], status: 404}
    end

  end

  def create
    unless User.has_permission(current_user, 'manage_acs_sets')
      render json: {errors: ["You do not have the ability to create acs sets"]}, status: 403
      return
    end

    @acs_set = AcsSet.create(acs_set_attrs)
    if @acs_set.valid?
      render json: @acs_set, status: 201
    else
      render json: {errors: @acs_set.errors.full_messages }, status: 400
    end
  end

  def update
    unless User.has_permission(current_user, 'manage_acs_sets')
      render json: {errors: ["You do not have the ability to update acs sets"]}, status: 403
      return
    end

    render json: {errors: ['Unable to process request']}, status: 400 unless acs_set_attrs[:id]

    @acs_set = AcsSet.find_by_guid(acs_set_attrs[:id])

    if @acs_set.present?
      # We need to modify the params, so it uses guid instead of id, otherwise we will get a
      # "Name has already been taken" error.
      params[:guid]=params[:id]
      params.delete(:id)
      @acs_set.update(acs_set_attrs)

      if @acs_set.valid?
        render json: @acs_set, status: 202
      else
        render json: {errors: @acs_set.errors.full_messages }, status: 400
      end
    else
      render json: {errors: ["Could not find ACS Set of id #{acs_set_attrs[:id]}"]},status: 404
    end
  end

  def destroy
    unless User.has_permission(current_user, 'manage_acs_sets')
      render json: {errors: ["You do not have the ability to destroy acs sets"]}, status: 403
      return
    end

    render json: {errors: ['Unable to process request']}, status: 400 unless acs_set_attrs[:id]

    @acs_set = AcsSet.find_by_guid(acs_set_attrs[:id])

    if @acs_set.present?
      if @acs_set.destroy
        render json: @acs_set, status: 202
      else
        render json: {errors: ['Set could not be deleted']}, status: 400
      end
    else
      render json: {errors: ["Could not find ACS Set of id #{acs_set_attrs[:id]}"]},status: 404
    end
  end

  private

  def acs_set_attrs
    params.permit(:id,
                  :guid,
                  :name,
                  STIX_MARKING_PERMITTED_PARAMS,
                  acs_sets_organizations_attributes: [:organization_id,:destroy]
    )
  end
end
