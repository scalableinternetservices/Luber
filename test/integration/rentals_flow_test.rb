require 'test_helper'

class RentalsFlowTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      username: 'RickSanchez',
      email: 'rick@sanchez.com',
      password: 'foobar',
      password_confirmation: 'foobar',
      signed_in_at: DateTime.now)

    @user2 = User.create!(
      username: 'MortySanchez',
      email: 'morty@sanchez.com',
      password: 'foobar',
      password_confirmation: 'foobar',
      signed_in_at: DateTime.now)

    @car = Car.create!(
      user_id: @user.id,
      make: 'Ford',
      model: 'Mustang',
      year: 2000,
      color: 'Red',
      license_plate: '8DEF234')

    @rental = Rental.create!(
      owner_id: @user.id,
      renter_id: nil,
      car_id: @car.id,
      start_location: 'Santa Barbara',
      end_location: 'Mountain View',
      start_time: '7376-10-17 20:20:37',
      end_time: '210294-10-18 20:20:37',
      price: 1.53,
      status: 0,
      terms: 'My terms')
  end

  test 'successfully create, modify, cancel, and delete a rental post' do
    sign_in_as(@user, password: 'foobar')
    get new_rental_url
    assert_template 'rentals/new'
    assert_select 'option', 'Red, 2000 Ford Mustang' # check that my cars are listed

    post rentals_url, params: { 
      rental: { 
        car_id: @car.id,
        start_location: 'Los Angeles',
        end_location: 'San Francisco',
        start_time: '2018-11-28 00:45:02',
        end_time: '2018-11-28 01:52:44',
        price: 184.77,
        terms: 'nonsmoking, happiness' } }
    myrental = Rental.last
    assert_redirected_to rental_path(myrental)
    follow_redirect!
    assert_template 'rentals/show'
    assert_not flash.blank?
    assert_select 'span', 'Available'
    assert_select 'span.rental_start_location_label', 'Los Angeles'
    assert_select 'span.rental_end_location_label', 'San Francisco'
    assert_select 'h3', '$184.77'
    assert_select 'p.list-group-item', 'From 12:45 AM on Wednesday, Nov. 28 until 1:52 AM on Wednesday, Nov. 28'
    assert_select 'p.list-group-item', 'Terms: nonsmoking, happiness'
    assert_select 'p > a', 'RickSanchez'
    assert_select 'p.list-group-item', 'Ford Mustang'
    assert_select 'a[href=?]', edit_rental_path(myrental)

    # edit this rental
    get edit_rental_path(myrental)
    assert_template 'rentals/edit'
    assert_select '#rental_car_id > option', 'Red, 2000 Ford Mustang'
    assert_select '#rental_start_location[value=?]', 'Los Angeles'
    assert_select '#rental_end_location[value=?]', 'San Francisco'
    # TODO: how to test the values of the start/end times?
    assert_select '#rental_price[value=?]', '184.77'
    assert_select '#rental_terms[value=?]', 'nonsmoking, happiness'

    # submit a new dank
    patch rental_url(myrental), params: { 
      rental: { 
        car_id: @car.id,
        start_location: 'Minneapolis',
        end_location: 'St. Paul',
        start_time: '3024-05-11 11:59:00.00',
        end_time: '3024-12-30 23:59:00.00',
        price: 0.01,
        terms: 'chronic, depression' } }
    assert_redirected_to rental_path(myrental)
    follow_redirect!
    assert_template 'rentals/show'
    assert_not flash.blank?
    assert_select 'span', 'Available'
    assert_select 'span.rental_start_location_label', 'Minneapolis'
    assert_select 'span.rental_end_location_label', 'St. Paul'
    assert_select 'h3', '$0.01'
    assert_select 'p.list-group-item', 'From 11:59 AM on Tuesday, May. 11 until 11:59 PM on Thursday, Dec. 30'
    assert_select 'p.list-group-item', 'Terms: chronic, depression'
    assert_select 'p > a', 'RickSanchez'
    assert_select 'p.list-group-item', 'Ford Mustang'
    assert_select 'a[href=?][data-method=patch]', cancel_rental_path(myrental)

    # cancel the rental
    patch cancel_rental_path(myrental)
    assert_redirected_to rental_url(myrental)
    follow_redirect!
    assert_template 'rentals/show'
    assert_select 'span', 'Canceled'
    assert_not flash.blank?
    assert_select 'a[href=?][data-method=delete]', rental_path(myrental)

    # delete the rental
    delete rental_url(myrental)
    assert_redirected_to overview_user_path(@user)
    assert_not flash.blank?
  end

  test 'successfully apply and cancel a rental post' do
    sign_in_as(@user2, password: 'foobar')
    get rental_url(@rental)
    assert_template 'rentals/show'
    assert_select 'a[href=?][data-method=patch]', rent_rental_path(@rental)

    patch rent_rental_path(@rental)
    assert_redirected_to rental_url(@rental)
    follow_redirect!
    assert_template 'rentals/show'
    assert_not flash.blank?
    assert_select '#rentals-show span.badge', 'Upcoming'
    assert_select '#rentals-show a[href=?][data-method=patch]', cancel_rental_path(@rental)

    patch cancel_rental_path(@rental)
    assert_redirected_to rental_url(@rental)
    follow_redirect!
    assert_template 'rentals/show'
    assert_not flash.blank?
    assert_select '#rentals-show span.badge', 'Canceled'
  end
end