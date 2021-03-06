class Office::RegistrationsController < Office::ApplicationController
  before_filter :event

  def edit
  end

  def update
    if @registration.update(registration_params)
      redirect_to([:office, @registration], :notice => 'Registration was successfully updated.')
    else
      render :edit
    end
  end

  def show
  end

  def destroy
    @registration.destroy
    redirect_to(status_office_event_report_path(@event), :notice => 'Registration was successfully deleted.')
  end

  def completed
    @registration.toggle_completed
    redirect_to(completed_office_event_report_path(@event), :notice => 'Toggled registration')
  end

  def checked_in
    @registration.toggle_checked_in
    redirect_to(checked_in_office_event_report_path(@event), :notice => 'Toggled registration')
  end

  private

  def registration_params
    params.require(:registration).permit!
  end

  def registration
    @registration ||= Registration.find(params[:id])
  end

  def event
    @event ||= registration.event
  end
end
