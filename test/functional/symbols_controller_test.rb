require 'test_helper'

class SymbolsControllerTest < ActionController::TestCase
  setup do
    @symbol = symbols(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:symbols)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  # test "should create symbol" do
  #   logger.info(@symbol.to_yaml())
  #   assert_difference('Symbol.count') do
  #     post :create, symbol: @symbol.attributes
  #   end

  #   assert_redirected_to symbol_path(assigns(:symbol))
  # end

  test "should show symbol" do
    get :show, id: @symbol
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @symbol
    assert_response :success
  end

  test "should update symbol" do
    put :update, id: @symbol, symbol: @symbol.attributes
    assert_redirected_to symbol_path(assigns(:symbol))
  end

  test "should destroy symbol" do
    assert_difference('Symbol.count', -1) do
      delete :destroy, id: @symbol
    end

    assert_redirected_to symbols_path
  end
end
