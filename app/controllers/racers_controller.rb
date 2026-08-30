class RacersController < ApplicationController
  before_action :authenticate_user!

  def index
    @full_course_edition = helpers.current_full_course_edition
    @kids_course_edition = helpers.current_kids_course_edition

    # racers older than the last race edition belong to a previous signup cycle
    cutoff_date = [@full_course_edition.previous_edition&.date, @kids_course_edition.previous_edition&.date].compact.min
    @racers = Racer.includes(race_entries: :race_edition).order(created_at: :desc)
    @racers = @racers.where("created_at > ?", cutoff_date) if cutoff_date

    @emails_with_current_entries = Racer.joins(:race_entries)
                                        .where(race_entries: { race_edition_id: [@full_course_edition.id, @kids_course_edition.id] })
                                        .pluck(:email)
                                        .to_set
  end

  def show
    @racer = Racer.find(params[:id])
  end

  def new
    @racer = Racer.new
  end

  def create
    @racer = Racer.new(obj_params)

    if @racer.save
      flash[:success] = "Your racer was created successfully!"
      redirect_to racers_path
    else
      render :new
    end
  end

  def edit
    @racer = Racer.find(params[:id])
  end

  def update
    @racer = Racer.find(params[:id])
    if @racer.update(obj_params)
      flash[:success] = "Your racer was updated successfully"
      redirect_to params[:return_to] || racer_path(@racer)
    end
  end

  private

  def obj_params
    params.require(:racer).permit(:first_name, :last_name, :email, :gender, :birth_date, :city, :state)
  end
end
