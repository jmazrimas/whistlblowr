require "cowsay"

class NewInvestigatorsController < ApplicationController

  before_action :confirm_admin, :load_investigators

  def new
    # @investigators = Investigator.order(:created_at)
  end

  def create

    email = params[:email]
    @investigator = Investigator.new(email: email, password: "secretsix")
    if @investigator.save
      @errors = ["user saved"]
      redirect_to '/investigator_admin'
    else
      @errors = ["user NOT saved"]
      redirect_to '/investigator_admin'
    end
  end

  def update
    # @investigators = Investigator.order(:created_at)
    # @investigator = Investigator.find_by(id: params[:id])

    if @investigator.admin && @investigators.where(admin: true).count > 1
      @investigator.admin = false
    elsif @investigator.admin
      @errors = ["That's the last admin!"]
    else
      @investigator.admin = true
    end

    @investigator.save
    redirect_to '/investigator_admin'
  end

  def delete
    # @investigators = Investigator.order(:created_at)
    # @investigator = Investigator.find_by(id: params[:id])
    @investigator.destroy

    redirect_to '/investigator_admin'
  end


  private

  def confirm_admin
    if current_investigator
      redirect_to '/' if !current_investigator.admin?
    else
      redirect_to '/'
    end
  end

  def load_investigators
    @investigators = Investigator.order(:created_at)
    if params[:id]
      @investigator = Investigator.find_by(id: params[:id])
    end
  end

end