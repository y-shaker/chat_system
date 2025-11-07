class ChatsController < ApplicationController
  before_action :set_application
  before_action :set_chat, only: [:show, :update, :destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :missing_params

  # GET /applications/:application_token/chats
  def index
    @chats = @application.chats
    render json: @chats
  end

  # GET /applications/:application_token/chats/:chat_number
  def show
    render json: @chat
  end

  # POST /applications/:application_token/chats
  # This is currently not used as we use Golang layer for message and chat creation requests
  def create
    key = "application:#{@application.id}:chats_seq"
    chat_number = $redis.incr(key)

    ChatCreateWorker.perform_async(@application.id, chat_number, chat_params[:title])

    render json: { number: chat_number }, status: :accepted
  end

  # PUT/PATCH /applications/:application_token/chats/:number
  def update
    if @chat.update(chat_params)
      render json: @chat
    else
      render json: { errors: @chat.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /applications/:application_token/chats/:number
  def destroy
    @chat.destroy
    head :no_content
  end

  private

  def set_application
    @application = Application.find_by!(token: params[:application_token])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Application not found" }, status: :not_found
  end

  def set_chat
    @chat = @application.chats.find_by!(number: params[:number])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Chat not found" }, status: :not_found
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
