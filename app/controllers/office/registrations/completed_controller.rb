class Office::Registrations::CompletedController < Office::RegistrationsController
  def index
  end
  
  # mark all registrations as completed=true if all=completed, otherwise
  # completed=false
  def create
    value = params[:all] == 'completed'
    registrations.each { |r| r.update_attribute(:completed, value) }
    redirect_to(office_event_completed_index_url(event))
  end

  # toggle value of completed attribute
  def update
    registration.update_attribute(:completed, !registration.completed)
    redirect_to(office_event_completed_index_url(event))
  end
end
