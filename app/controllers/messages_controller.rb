class MessagesController < ApplicationController
  before_action :set_message_context, only: [:show, :update, :destroy]
  before_action :set_chat_context, only: [:index, :search]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :missing_params

  # GET /applications/:application_token/chats/:chat_number/messages
  def index
    @messages = @chat.messages.select(:number, :body, :created_at)
    render json: @messages
  end

  # GET /applications/:application_token/chats/:chat_number/messages/:number
  def show
    render json: @message
  end

  # PATCH/PUT /applications/:application_token/chats/:chat_number/messages/:number
  def update
    if @message.update(message_params)
      render json: @message
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /applications/:application_token/chats/:chat_number/messages/:number
  def destroy
    @message.destroy
    head :no_content
  end

  def search
    query = params[:q]
    return render json: { error: 'Search query is required' }, status: :bad_request if query.blank?

    begin
      results = Message.search(
        query: {
          bool: {
            must: [{ match: { body: query } }],
            filter: [{ term: { chat_id: @chat.id } }]
          }
        }
      )

      render json: results.records
    rescue => e
      Rails.logger.error "[MessagesController#search] Search failed: #{e.message}"
      render json: { error: 'Search failed', message: e.message }, status: :internal_server_error
    end
  end

  private

  # Single query chain Application → Chat → Message
  def set_message_context
    @message = Message
      .joins(chat: :application)
      .includes(chat: :application)
      .select('messages.*')
      .find_by!(
        number: params[:number],
        chats: { number: params[:chat_number] },
        applications: { token: params[:application_token] }
      )

    @chat = @message.chat
    @application = @chat.application
  end

  def set_chat_context
    @chat = Chat.joins(:application)
                .includes(:application)
                .select('chats.*')
                .find_by!(
                  number: params[:chat_number],
                  applications: { token: params[:application_token] }
                )
    @application = @chat.application
  end

  def message_params
    params.fetch(:message, {}).permit(:body)
  end

  def record_not_found(error)
    render json: { error: error.message }, status: :not_found
  end

  def missing_params(error)
    render json: { error: "Missing required parameter: #{error.param}" }, status: :bad_request
  end
end
