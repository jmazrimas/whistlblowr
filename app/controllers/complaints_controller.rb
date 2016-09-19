require "cowsay"
require_relative "../uploaders/media_uploader"

class ComplaintsController < ApplicationController
  before_action :authenticate_investigator!, except: [:new, :show, :create]
  skip_before_action :verify_authenticity_token
  before_filter :cors_preflight_check

  def index
    @complaints = Complaint.all.order("created_at DESC").page(params[:page]).per(10)
  end

  def new
    @complaint = Complaint.new
    allegation =  Allegation.new
    @complaint.allegations << allegation
    @allegations = @complaint.allegations
    @allegations_list = AllegationType.all
  end

  def create
    @message = Message.new
    @complaint = Complaint.new(complaint_params)
    @complaint.user = return_user
    if params[:complaint][:video_links]
      params[:complaint][:video_links].each do |n, l|
        @complaint.video_links << VideoLink.create(url: l) unless l == ""
      end
    end

    if @complaint.save
      respond_to do |format|
        format.js do
          render json: @complaint, content_type: "application/json"
        end

        format.html do
          flash[:comp_key] = @complaint.key
          flash[:comp_message] = @complaint.content
          redirect_to complaints_find_path(:complaint_key => @complaint.key)    
        end
      end

    else

      @errors = @complaint.errors.full_messages
      render "new"
    end
  end

  def show
    @investigator_authenticated = false
    @investigator_authenticated = true if current_investigator
    @message = Message.new
    @complaint = @complaint ? @complaint : Complaint.find_by(key: params[:complaint_key])
    if @complaint == nil
      redirect_to "/errors/not_found"
    else
      @messages = @complaint.messages.order("created_at DESC").page(params[:page]).per(10)
      @complaint.messages.each {|m| m.update_attribute(:viewed, true)}
    end
  end

  def edit
    @complaint = Complaint.find_by(key: params[:complaint_key])
  end

  def update
    @complaint = Complaint.find_by(key: params[:complaint_key])
    @complaint.update_attribute(:status, params[:status])
    respond_to do |format|
      format.js {render json: @complaint, status_code: "200"}
      format.html {redirect_to complaints_path}
    end
  end

  def delete

  end

  def download
    @complaint = Complaint.find_by(key: params[:complaint_key])
    file = @complaint.zip_media
    File.open(file, 'r') do |f|
      send_data f.read, type: "application/zip", filename: file
    end
    FileUtils.rm(file)
  end

  def podio_export
    @complaint = Complaint.find_by(id: params[:id])
    @message = Message.new
    if @complaint.exists_in_podio?
      @errors = ["This complaint/tip has already been sent to Podio"]
    else
      @complaint.update_attribute(:status, "Initiated-Investigation")
      @complaint.export_to_podio

      respond_to do |format|
        format.html { redirect_to(:back) }
        format.js {}
      end

    end

  end


  def cors_preflight_check
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end


  private

    # def add_allegation_types
    #   params[:complaint][:allegation_types].each do |type, value|
    #     allegation = AllegationType.find(type.to_i)
    #     @complaint.allegation_types << allegation if value.to_i == 1
    #   end
    # end

    def complaint_params
      params.require(:complaint).permit(:content, {media: []}, :video_links_array)
    end

    def return_user
      up = user_params[:user]
      User.find_or_create_by(up)
    end

    def user_params
      params.require(:complaint).permit(user: [:name, :email, :phone])
    end

end
