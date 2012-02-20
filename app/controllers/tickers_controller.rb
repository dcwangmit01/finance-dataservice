class TickersController < ApplicationController
  # GET /tickers
  # GET /tickers.json
  def index
    @tickers = Ticker.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @tickers }
    end
  end

  # GET /tickers/1
  # GET /tickers/1.json
  def show
    @ticker = Ticker.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ticker }
    end
  end

  # GET /tickers/new
  # GET /tickers/new.json
  def new
    @ticker = Ticker.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ticker }
    end
  end

  # GET /tickers/1/edit
  def edit
    @ticker = Ticker.find(params[:id])
  end

  # POST /tickers
  # POST /tickers.json
  def create
    @ticker = Ticker.new(params[:ticker])

    respond_to do |format|
      if @ticker.save
        format.html { redirect_to @ticker, notice: 'Ticker was successfully created.' }
        format.json { render json: @ticker, status: :created, location: @ticker }
      else
        format.html { render action: "new" }
        format.json { render json: @ticker.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /tickers/1
  # PUT /tickers/1.json
  def update
    @ticker = Ticker.find(params[:id])

    respond_to do |format|
      if @ticker.update_attributes(params[:ticker])
        format.html { redirect_to @ticker, notice: 'Ticker was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @ticker.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tickers/1
  # DELETE /tickers/1.json
  def destroy
    @ticker = Ticker.find(params[:id])
    @ticker.destroy

    respond_to do |format|
      format.html { redirect_to tickers_url }
      format.json { head :no_content }
    end
  end
end
