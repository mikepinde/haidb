# -*- coding: utf-8 -*-
require 'spec_helper'

describe PublicSignup do
  context "#new validations" do
    it "should have default values after new" do
      public_signup = PublicSignup.new(registration_attributes: {})
      public_signup.registration.role.should == Registration::PARTICIPANT
      public_signup.registration.should be_pending
      public_signup.registration.payment_method.should_not be
    end

    it "should be valid with min attributes" do
      valid_ps = FactoryGirl.build(:public_signup)
      valid_ps.should be_valid
    end

    context "language of messages" do
      context "en" do
        before(:each) { I18n.locale = :en }
        it "should have English errors" do
          invalid_public_signup = PublicSignup.create(:terms_and_conditions => false)
          invalid_public_signup.errors.messages.should == {
              :terms_and_conditions=>["must be accepted"]
          }
        end
      end
      context "de" do
        before(:each) { I18n.locale = :de }
        it "should have German errors" do
          invalid_public_signup = PublicSignup.create(:terms_and_conditions => false)
          invalid_public_signup.errors.messages.should == {
              :terms_and_conditions=>["muss akzeptiert werden"]
          }
        end
      end
    end
  end

  context "#approve!" do
    it "should set the approved_at date & mark the registration as approved" do
      ps = FactoryGirl.create(:public_signup)
      ps.registration.should be_pending
      ps.approved_at.should_not be
      ps.approve!
      ps.approved_at.should be
      ps.registration.should be_approved
    end
  end

  context "#waitlist!" do
    it "should set record as waitlisted" do
      ps = FactoryGirl.create(:public_signup)
      ps.registration.should be_pending
      ps.waitlist!
      ps.approved_at.should_not be
      ps.registration.should be_waitlisted
    end
  end

  context "delegation" do
    it "should handle these fields" do
      registration = FactoryGirl.build(:registration)
      ps = FactoryGirl.build(:public_signup, :registration => registration)
      ps.full_name.should == registration.full_name
      ps.event_name.should == registration.event_name
      ps.gender.should == registration.gender
      ps.email.should == registration.email
    end
  end

  context "helpers" do
    it "should have a display_name" do
      ps = FactoryGirl.build(:public_signup)
      ps.display_name.should be
    end
  end

  context "record counts" do
    it "should destroy registration when public_signup is destroyed" do
      public_signup = FactoryGirl.create(:public_signup)
      PublicSignup.should have(1).record
      Registration.should have(1).record

      public_signup.destroy

      PublicSignup.should have(:no).records
      Registration.should have(:no).records
    end
  end

  context "group_by_event" do
    let(:event1) { create(:event, start_date: Date.today) }
    let(:event2) { create(:event, start_date: Date.today + 1.week) }
    let(:public_signup1) { create(:public_signup, registration: create(:registration, event: event2)) }
    let(:public_signup2) { create(:public_signup, registration: create(:registration, event: event1)) }
    subject { PublicSignup.group_by_event }

    before do
      public_signup1
      public_signup2
    end

    it "should have two arrays" do
      expect(subject).to eq([[public_signup2], [public_signup1]])
    end
  end
end
