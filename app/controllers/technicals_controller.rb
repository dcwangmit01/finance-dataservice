class TechnicalsController < ApplicationController
  def create
    @ticker = Ticker.find(params[:ticker_id])
    @technical = @ticker.technicals.create(params[:technical])
    redirect_to ticker_path(@ticker)
  end

  def destroy
    @ticker = Ticker.find(params[:ticker_id])
    @technical = @ticker.technicals.find(params[:id])
    @technical.destroy
    redirect_to ticker_path(@ticker)
  end
end
