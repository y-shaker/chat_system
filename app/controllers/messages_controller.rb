class MessagesController < ApplicationController
  before_action :set_application
  before_action :set_chat
  before_action :set_message, only: [:show, :update, :destroy]
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActionController::ParameterMissing, with: :missing_params

  # GET /applications/:application_token/chats/:chat_number/messages
  def index
    @messages = @chat.messages
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

    Rails.logger.info "[MessagesController#search] Searching for '#{query}' in chat #{@chat.id}"

    begin
      results = Message.search(
        query: {
          bool: {
            must: [
              { match: { body: query } }
            ],
            filter: [
              { term: { chat_id: @chat.id } }
            ]
          }
        }
      )

      Rails.logger.info "[MessagesController#search] Found #{results.results.total} results"

      render json: results.records
    rescue => e
      Rails.logger.error "[MessagesController#search] Search failed: #{e.message}"
      render json: { error: 'Search failed', message: e.message }, status: :internal_server_error
    end
  end

  private

  def set_application
    @application = Application.find_by!(token: params[:application_token])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Application not found' }, status: :not_found
  end

  def set_chat
    @chat = @application.chats.find_by!(number: params[:chat_number])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Chat not found' }, status: :not_found
  end

  def set_message
    @message = @chat.messages.find_by!(number: params[:number])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Message not found' }, status: :not_found
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
