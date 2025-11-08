class ChatsController < ApplicationController
  before_action :set_chat_context, only: [:show, :update, :destroy]
  before_action :set_application, only: [:index]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :missing_params

  # GET /applications/:application_token/chats
  def index
    @chats = @application.chats.select(:number, :title, :messages_count, :created_at)
    render json: @chats
  end

  # GET /applications/:application_token/chats/:chat_number
  def show
    render json: @chat
  end

  # PUT/PATCH /applications/:application_token/chats/:chat_number
  def update
    if @chat.update(chat_params)
      render json: @chat
    else
      render json: { errors: @chat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /applications/:application_token/chats/:chat_number
  def destroy
    @chat.destroy
    head :no_content
  end

  private

  def set_chat_context
    Rails.logger.info("Fetching chat number=#{params[:number]} for app_token=#{params[:application_token]}")
    @chat = Chat.joins(:application)
                .includes(:application)
                .select('chats.*')
                .find_by!(
                  number: params[:number],
                  applications: { token: params[:application_token] }
                )
    @application = @chat.application
  end

  def set_application
    @application = Application.find_by!(token: params[:application_token])
  end

  def chat_params
    params.fetch(:chat, {}).permit(:title)
  end

  def record_not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def missing_params(error)
    render json: { error: "Missing required parameter: #{error.param}" }, status: :bad_request
  end
end
