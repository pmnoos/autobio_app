require "application_system_test_case"

class AuthVisibilityTest < ApplicationSystemTestCase
  def sign_in_as(email:, password: "password")
    visit new_session_url
    fill_in "email_address", with: email
    fill_in "password", with: password
    click_button "Sign in"
  end

  test "unauthenticated user does not see PDF notices or export buttons on home" do
    visit root_url

    assert_no_text "Sign in to export as PDF or DOCX."
    assert_no_text "Sign in to download the complete book as PDF."
    assert_no_link "Download PDF"
    assert_no_link "Download DOCX"
    assert_no_text "Created "
  end

  test "authenticated user sees export buttons and created dates on home" do
    user = users(:one)
    sign_in_as(email: user.email_address)
    assert_text "Welcome, #{user.email_address}"

    visit root_url

    assert_link "Download PDF"
    assert_link "Download DOCX"
    assert_text "Created"
  end

  test "list page hides notice and export when unauthenticated, shows export when authenticated" do
    visit list_chapters_url

    assert_no_text "Sign in to export PDF"
    assert_no_link "📄 Export Complete Book as PDF"

    user = users(:one)
    sign_in_as(email: user.email_address)
    assert_text "Welcome, #{user.email_address}"

    visit list_chapters_url
    assert_link "📄 Export Complete Book as PDF"
  end

  test "show page hides notice and PDF button when unauthenticated, shows PDF when authenticated" do
    chapter = chapters(:one)

    visit chapter_url(chapter)
    assert_no_text "Sign in to export PDF"
    assert_no_link "PDF"

    user = users(:one)
    sign_in_as(email: user.email_address)
    assert_text "Welcome, #{user.email_address}"

    visit chapter_url(chapter)
    assert_link "PDF"
  end
end
