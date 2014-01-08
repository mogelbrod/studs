class EventsController < ApplicationController
  respond_to :html
  before_filter :set_event, only: [:show, :edit, :update, :destroy, :delete]
  load_and_authorize_resource

  def index
    @events = Event.all
    @past_events = Event.where("end_date <= ?", Time.zone.now).order("start_date DESC")
    @upcoming_events = Event.where("end_date > ?", Time.zone.now).order("start_date ASC")
    if logged_in? && current_user.organization?
      @my_events = current_user.events
      if current_user.has_one_event?
        redirect_to @my_events.first and return
      end
    end
    respond_with(@events)
  end

  def show
    respond_with(@event)
  end

  def new
    @event = Event.new
    respond_with(@event)
  end

  def edit
  end

  def create
    @event = Event.new(params[:event])
    user_ids = params[:user][:user_id] - [""]
    users = User.find(user_ids)
    @event.users << users
    @event.save
    respond_with(@event)
  end

  def update
    @event.update_attributes(params[:event])
    user_ids = params[:user][:user_id] - [""]
    users = User.find(user_ids)
    @event.users = users
    @event.save
    respond_with(@event)
  end

  def delete
  end

  def destroy
    @event.destroy
    respond_with @event, location: events_path
  end

  private
    def set_event
      @event = Event.find(params[:id])
    end
end