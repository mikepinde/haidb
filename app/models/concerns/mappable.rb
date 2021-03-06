module Mappable
  extend ActiveSupport::Concern

  included do
    acts_as_gmappable address: 'full_address', lat: 'lat', lng: 'lng', validation: false
  end

  ADDRESS_FIELDS = [:address, :postal_code, :city, :country]

  def geocoded?
    lat.present? && lng.present?
  end

  def full_address
    ADDRESS_FIELDS.map {|field| send(field)}.reject(&:blank?).join(", ")
  end

  def address_has_changed?
    ADDRESS_FIELDS.map { |f| attribute_changed?(f.to_s) }.any?
  end

  # return true if new geocode is NOT necessary
  def gmaps
    return true if self.class.disable_mappable
    return true if full_address.blank?
    return true if geocoded? && !address_has_changed?
    false
  end
  attr_writer :gmaps

  module ClassMethods
    def disable_mappable
      return true if Rails.env.test?
    end
  end
end