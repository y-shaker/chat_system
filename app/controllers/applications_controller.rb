class ApplicationsController < ApplicationController
  before_action :set_application, only: [:show, :update, :destroy]

  # GET /applications
  def index
    @applications = Application.all
    render json: @applications
  end

  # GET /applications/:token
  def show
    render json: @application
  end

  # POST /applications
  def create
    @application = Application.new(application_params)

    if @application.save
      render json: { token: @application.token, name: @application.name }, status: :created
    else
      render json: { errors: @application.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /applications/:token
  def update
    if @application.update(application_params)
      render json: @application
    else
      render json: { errors: @application.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /applications/:token
  def destroy
    @application.destroy
    head :no_content
  end

  private

  def set_application
    @application = Application.find_by!(token: params[:token])
  end

  def application_params
    params.require(:application).permit(:name)
  end
end
