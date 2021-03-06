module Office::AngelsHelper

  def options_for_country(form)
    defaults = if Site.de?
                 %w(DE AT NL GB)
               else
                 %w(GB)
               end
    {as: :country, :priority => defaults}
  end

  # TODO fix
  def options_for_angel_select(form)
    {:as => :select, :label => 'Angel', :collection => Angel.by_full_name, label_method: :full_name_with_context, value_method: :id}
  end

  def no_angels_on_map(height = '400px')
    content_tag(:div, :style => "width: 100%; line-height: #{height};") do
      content_tag(:h2, :style => 'text-align: center; font-size: 30px; background: white; color: white; text-shadow: black 0px 0px 2px;') do
        "No angels match your search criteria"
      end
    end
  end

  def angel_membership_status(angel)
    membership = angel.memberships.active.first
    if membership
      content_tag(:i, membership.status)
    end
  end

  def link_to_angel(angel)
    link_to(office_angel_path(angel)) do
      content_tag(:span, angel.full_name) + angel_icon(angel)
    end
  end

  def angel_icon(angel, size=40)
    url = angel.gravatar.image_url(ssl: true, rescue_errors: true, size: size, rating: 'x', default: 'mm')
    tag(:img, src: url, class: 'angel-icon')
  end
end
