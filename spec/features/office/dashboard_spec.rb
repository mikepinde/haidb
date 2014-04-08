require 'spec_helper'

describe "dashboard", js: true do
  before do
    office_login
  end

  it "should run web browser test" do
    visit office_dashboards_path
    expect(Staff.count).to eq(1)
    # page.save_screenshot('test.png', full: true)
    expect(page).to have_link('Dashboard')
  end
end