class ThreatActorsController < ApplicationController
  include StixMarkingHelper

  before_filter :isa_params, only: [:create,:update]

  def create
    if !User.has_permission(current_user, 'create_remove_threat_actors')
      render json: {errors: ["You do not have the ability to create threat actors"]}, status: 403
      return
    end
    
    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end

    if User.has_permission(current_user,'add_indicator_to_threat_actor')
      params[:indicator_stix_ids] ||= []
    end

    @threat_actor = ThreatActor.new(threat_actor_params)

    if params[:indicator_stix_ids].length > 0
      if !User.has_permission(current_user,'add_indicator_to_threat_actor')
        render json: {errors: ["You do not have the ability to add indicators to threat actors"]}, status: 403
        return
      end
      @threat_actor.indicator_stix_ids = params[:indicator_stix_ids]||[]
    end

    validate(@threat_actor)

    validation_errors = {:base => []}

    # Look through all the indicators_threat_actors and find errors. Add them to the errors array.
    @threat_actor.indicators_threat_actors.each do |ita|
      if ita.errors.messages.present? && ita.errors.messages[:base].present?
        ita.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # if validate comes back with errors, we probably have a error in indicators_threat_actors
    unless validation_errors[:base].blank?
      render json: {errors: validation_errors}, status: 403
      return
    end
  end

  def show
    @threat_actor = includes_indicators(ThreatActor.includes(audits: :user,stix_markings: [:isa_marking_structure,:tlp_marking_structure,:simple_marking_structure,{isa_assertion_structure: [:isa_privs,:further_sharings]}])).find_by_stix_id(params[:id])
    
    if @threat_actor
      # We don't create the default markings on ingest anymore for performance
      # reasons, so create them now, if needed
      ThreatActor.apply_default_policy_if_needed(@threat_actor)
      @threat_actor.reload
    end

    render json: @threat_actor, locals: {associations: {observables: 'embedded'}}
  end

  def index
    @threat_actors = ThreatActor.where(:stix_id => params[:ids]) if params[:ids]
    limit = record_limit(params[:amount].to_i)
    offset = params[:offset] || 0
    marking_search_params = nil
    if params[:marking_search_params].present?
      marking_search_params = JSON.parse params[:marking_search_params]
    end

    if params[:q].present?
      solr_offset = offset
      solr_limit = limit
      
      # If performing a SOLR based search AND a Stix Marking search we need to do a two-step query
      # First, we perform the SOLR based query and grab the ids of the first 1000 results.
      # We use those IDs to limit the SQL query that will feed the Stix Marking search
      if marking_search_params.present?
        solr_offset = 0
        solr_limit = 1000
      end
      search = Search.threat_actor_search(params[:q], {
        column: params[:column],
        direction: params[:direction],
        ebt: params[:ebt],
        iet: params[:iet],
        limit: (solr_limit || Sunspot.config.pagination.default_per_page),
        offset: solr_offset
      })

      if marking_search_params.present?
        @threat_actors ||= ThreatActor.all.reorder(updated_at: :desc).includes(:created_by_user)
        @threat_actors = @threat_actors.where(id: search.results.collect {|ta| ta.id})
      else
        total_count = search.total
        @threat_actors = search.results
      end
      
      @threat_actors ||= []
    else
      @threat_actors ||= ThreatActor.all.reorder(updated_at: :desc).includes(:created_by_user)

      @threat_actors = @threat_actors.where(created_at: params[:ebt]..params[:iet]) if params[:ebt].present? && params[:iet].present?
      @threat_actors = @threat_actors.where(title: params[:title]) if params[:title].present?
      @threat_actors = @threat_actors.where(short_description: params[:short_description]) if params[:short_description].present?
      @threat_actors = @threat_actors.classification_limit(params[:classification_limit]) if params[:classification_limit] && Classification::CLASSIFICATIONS.include?(params[:classification_limit])
      @threat_actors = @threat_actors.classification_greater(params[:classification_greater]) if params[:classification_greater] && Classification::CLASSIFICATIONS.include?(params[:classification_greater])
      @threat_actors = apply_sort(@threat_actors, params)
    end
    
    if marking_search_params.present?
      # We need to search markings both that are attached to this object or that may be
      # available through an AcsSet. Since Rails doesn't support Unions, we need to make it
      # it through straight sql
      
      # We need to limit the columns being queried to eliminate CLOB columns. Oracle doesn't like
      # CLOB columns in a FROM clause. Limit to only the columns in the grid or required by the query
      # Remove any existing ordering as it will create invalid SQL
      from_query = @threat_actors.reorder('').select("threat_actors.id as id, " +
          "threat_actors.stix_id as stix_id, threat_actors.guid as guid, " +
             "threat_actors.acs_set_id as acs_set_id, threat_actors.title as title, " +
             "threat_actors.created_at as created_at, threat_actors.updated_at as updated_at")
      
      scope_normal = from_query.joins(:stix_markings)
      scope_normal = add_stix_markings_constraints(scope_normal, marking_search_params)
      
      scope_acs = from_query.joins(:acs_set).joins("JOIN stix_markings ON stix_markings.remote_object_id = acs_sets.guid and stix_markings.remote_object_type = 'AcsSet'")
      scope_acs = add_stix_markings_constraints(scope_acs, marking_search_params)
      
      order = sanitize_sort_order(ThreatActor.column_names, params[:column])
      direction = sanitize_sort_direction(params[:direction])
      
      partial_results = ThreatActor.from("(#{scope_normal.to_sql} UNION #{scope_acs.to_sql} ORDER BY #{order} #{direction}) threat_actors")

      total_count = partial_results.count
      partial_results = partial_results.limit(limit).offset(offset)
              
      # Now requery to get the full objects
      @threat_actors = ThreatActor.where(id: partial_results.collect{|rslt| rslt.id})
      @threat_actors = apply_sort(@threat_actors, params)
    end
    
    # We still need a total count if this was a DB based search without stix marking
    if total_count.nil?
      total_count = @threat_actors.count
      @threat_actors = @threat_actors.limit(limit).offset(offset)
    end

    @metadata = Metadata.new
    @metadata.total_count = total_count
    
    respond_to do |format|
      format.any(:json, :html) { render json: {metadata: @metadata, threat_actors: @threat_actors} }
      format.csv {render "threat_actors/index.csv.erb"}
    end
  end

  def fo_stats
    if params[:ebt] && params[:iet]
      threat_actors = ThreatActor.unscoped.where(indicators_threat_actors: {created_at: params[:ebt]..params[:iet]}).where("title LIKE 'FO%'").joins(:indicators_threat_actors).group(:title,:stix_id).pluck(:title,:stix_id,"count(*)")
    else
      threat_actors = ThreatActor.unscoped.where("title LIKE 'FO%'").joins(:indicators_threat_actors).group(:title,:stix_id).pluck(:title,:stix_id,"count(*)")
    end

    # threat_actors now holds:  [0] - title, [1] - stix_id, [2] - count of indicators

    if (params[:direction] == 'asc' || params[:direction] == 'desc')
      if (params[:column] == 'title')
        col = params[:column].to_sym
        dir = params[:direction].to_sym
        threat_actors = threat_actors.sort{ |x, y| x[0] <=> y[0] }
      else
        threat_actors = threat_actors.sort{ |x, y| x[2] <=> y[2] }
      end
      if params[:direction] == 'desc'
        threat_actors = threat_actors.reverse
      end
    else
      threat_actors = threat_actors.sort{ |x, y| x[0] <=> y[0] }
    end

    @threat_actors = []
    threat_actors.each { |t| @threat_actors << {title: t[0], stix_id: t[1], count: t[2]} }

    render json: {threat_actors: @threat_actors}
  end

  def update
    if User.has_permission(current_user,'add_indicator_to_threat_actor')
      params[:indicator_stix_ids] ||= []
    end

    @threat_actor = ThreatActor.find_by_stix_id(params[:id])

    if params[:indicator_stix_ids].length > 0 || @threat_actor.indicators.length != params[:indicator_stix_ids].length
      if !User.has_permission(current_user,'add_indicator_to_threat_actor')
        render json: {errors: ["You do not have the ability to add indicators to threat actors"]}, status: 403
        return
      end
      @threat_actor.indicator_stix_ids = params[:indicator_stix_ids]||[]
    elsif (!Permissions.can_be_modified_by(current_user, @threat_actor))
      render json: {errors: ["You do not have the ability to modify threat actors"]}, status: 403
      return
    end

    if params[:acs_set_id].present?
      unless AcsSet.for_org(User.current_user.organization).collect(&:guid).include?(params[:acs_set_id])
        render json: {errors: ["You do not have the ability to associate this object with this ACS Set"]}, status: 403
        return
      end
    end

    Audit.justification = params[:justification] if params[:justification]
    @threat_actor.update(threat_actor_params)
    validate(@threat_actor)

    validation_errors = {:base => []}

    # Look through all the indicators_threat_actors and find errors. Add them to the errors array.
    @threat_actor.indicators_threat_actors.each do |ita|
      if ita.errors.messages.present? && ita.errors.messages[:base].present?
        ita.errors.messages[:base].each do |m|
          validation_errors[:base] << m
        end
      end
    end

    # if validate comes back with errors, we probably have a error in indicators_threat_actors
    unless validation_errors[:base].blank?
      render json: {errors: validation_errors}, status: 403
      return
    end
  end

  def destroy
    @threat_actor = ThreatActor.find_by_stix_id(params[:id])
    if !User.has_permission(current_user, 'create_remove_threat_actors') || !Permissions.can_be_deleted_by(current_user, @threat_actor)
      render json: {errors: ["You do not have the ability to delete threat actors"]}, status: 403
      return
    end
    if @threat_actor.destroy
      head 204
    else
      render json: {errors:{} },status: :unprocessable_entity
    end
  end

  def pmap
    @threat_actor = ThreatActor.where('upper(title)=?',params[:tag_name].upcase).first
    if @threat_actor.blank?
      render json: {errors: ["Could not find '#{params[:tag_name]}'"]}, status: 404
      return
    end
    send_data @threat_actor.to_pmap, :type => 'text/pmap', :filename => "#{@threat_actor.title.downcase}.pmap.txt"
  end

  def ipset
    @threat_actor = ThreatActor.where('upper(title)=?',params[:tag_name].upcase).first
    if @threat_actor.blank?
      render json: {errors: ["Could not find '#{params[:tag_name]}'"]}, status: 404
      return
    end
    send_data @threat_actor.to_ipset, :type => 'text/ipset', :filename => "#{@threat_actor.title.downcase}.ipset.txt"
  end

  def bulk_inds
    # Make sure we only get the params that were expecting
    params.permit(:indicator_stix_ids, :threat_actors_stix_ids)

    # keep track of how many threat_actors we have updated.
    amount_threat_actors = 0

    # Create an array of validation errors.
    validation_errors = {errors: []}

    # For each threat_actor that we get we need to add the indicators to it if it doesnt exist.
    params[:threat_actors_stix_ids].each do |e|
      @threat_actor = ThreatActor.find_by_stix_id(e)
      
      if params[:indicator_stix_ids].present?
        if !User.has_permission(current_user,'add_indicator_to_threat_actor')
          validation_errors[:errors] << "You do not have the ability to add indicators to threat actors"
          next
        end
        if !Permissions.can_be_modified_by(current_user, @threat_actor)
          validation_errors[:errors] << "You do not have the ability to modify threat actors"
          next
        end

        # subtract the params array of guids from the existing ones so we dont get dups.
        to_add_indicators = params[:indicator_stix_ids] - @threat_actor.indicator_ids

        # check if theirs anything new to add to the array of system tags
        if to_add_indicators.present?
          # wrap the add in a try catch block incase classification errors occur.
          begin
            to_add_indicators.each do |id_to_be_linked|
              obj = Indicator.find_by_stix_id(id_to_be_linked)
              if obj.present? && @threat_actor.portion_marking.present? && obj.portion_marking.present? && Classification::CLASSIFICATIONS.index(@threat_actor.portion_marking) < Classification::CLASSIFICATIONS.index(obj.portion_marking)
                render json: {errors: ["Invalid Classification, Classification of a selected Threat Actor is less than the classification of the selected Indicator(s)"]}, status: 403
                return
              end
            end

            @threat_actor.indicator_stix_ids = @threat_actor.indicator_ids.concat(to_add_indicators)
            amount_threat_actors += 1

            if !@threat_actor.valid?
              validation_errors[:errors] << @threat_actor.title + " : " + @threat_actor.errors
            end
          rescue Exception => e
            validation_errors[:errors] << @threat_actor.title + " : " + e.to_s 
            next
          end
        else
          validation_errors[:errors] << @threat_actor.title + " : " + "No new Indicators to add."
        end
      else
        validation_errors[:errors] << @threat_actor.title + " : " + "No Indicators selected."
      end
    end

    # build the toastr message that will be rendered 
    success_string = "Successfully Added " + params[:indicator_stix_ids].count.to_s + " Indicators to " + amount_threat_actors.to_s + "/" + params[:threat_actors_stix_ids].count.to_s + " Threat Actors."
    render json: {base: success_string, errors: validation_errors[:errors]}
  end

private

  def validate(object)
    if object.save
      render json: object
    else
      render json: {errors: object.errors}, status: :unprocessable_entity
    end
  end

  def threat_actor_params
    # Handle deep_munge and allow empty set
    params[:indicator_stix_ids] ||= []

    params.permit(:title,
                  :stix_id,
                  :description,
                  :short_description,
                  :acs_set_id,
                  :identity_name,
                  STIX_MARKING_PERMITTED_PARAMS)
  end

end
