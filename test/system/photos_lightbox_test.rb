require "application_system_test_case"

class PhotosLightboxTest < ApplicationSystemTestCase
  test "clicking a photo opens lightbox" do
    # Ensure at least one photo exists with an attachment
    photo = photos(:one)
    visit photos_url

    # Find the first clickable tile
    link = find(".tile a", match: :first)
    link.click

    # Lightbox should appear
    assert_selector "#lightbox", visible: true
    assert_selector "#lightbox-image", visible: true
  end
end
