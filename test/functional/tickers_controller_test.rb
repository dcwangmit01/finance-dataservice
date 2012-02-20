require 'test_helper'

class TickersControllerTest < ActionController::TestCase
  setup do
    @ticker = tickers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:tickers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create ticker" do
    assert_difference('Ticker.count') do
      post :create, ticker: @ticker.attributes
    end

    assert_redirected_to ticker_path(assigns(:ticker))
  end

  test "should show ticker" do
    get :show, id: @ticker
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @ticker
    assert_response :success
  end

  test "should update ticker" do
    put :update, id: @ticker, ticker: @ticker.attributes
    assert_redirected_to ticker_path(assigns(:ticker))
  end

  test "should destroy ticker" do
    assert_difference('Ticker.count', -1) do
      delete :destroy, id: @ticker
    end

    assert_redirected_to tickers_path
  end
end
