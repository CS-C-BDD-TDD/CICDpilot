class NotesController < ApplicationController
  def create
    if params["targetClass"] != "Indicator"
      render json: {errors: ["You may only add notes to indicators"]}, status: :unprocessable_entity
    end
    if !User.has_permission(current_user, 'create_analyst_notes')
      render json: {errors: ["You are not authorized to add a note"]}, status: 403
    end
    @note = Note.new
    @note.target_class = params["targetClass"]
    @note.target_guid = params["targetGuid"]
    @note.user = current_user
    @note.note = params["note"]
    if @note.save
      render json: @note
    else
      render json: {errors: ["Unable to save note"]}, status: :unprocessable_entity
    end
  end
  def destroy
    @note = Note.find_by_guid(params["id"])
    if @note.user != current_user
      render json: {errors: ["You are not allowed to remove this note"]}, status: 403
    end
    if !User.has_permission(current_user, 'create_analyst_notes')
      render json: {errors: ["You are not authorized to remove notes"]}, status: 403
    end
    if @note.destroy
      render json: {}, status: 200
    else
      render json: {errors: ["Unable to destroy"]}, status: :unprocessable_entity
    end
  end
end
