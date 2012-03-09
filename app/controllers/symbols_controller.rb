class SymbolsController < ApplicationController
  # GET /symbols
  # GET /symbols.json
  # GET /symbols.xml
  def index
    @symbols = Symbol.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @symbols }
      format.xml  { render xml:  @symbols }
    end
  end

  # GET /symbols/1
  # GET /symbols/1.json
  # GET /symbols/1.xml
  def show
    @symbol = Symbol.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @symbol }
      format.xml  { render xml:  @symbol }
    end
  end

  # GET /symbols/new
  # GET /symbols/new.json
  # GET /symbols/new.xml
  def new
    @symbol = Symbol.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @symbol }
      format.xml  { render xml:  @symbol }
    end
  end

  # GET /symbols/1/edit
  def edit
    @symbol = Symbol.find(params[:id])
  end

  # POST /symbols
  # POST /symbols.json
  def create
    @symbol = Symbol.new(params[:symbol])

    respond_to do |format|
      if @symbol.save
        format.html { redirect_to @symbol, notice: 'Symbol was successfully created.' }
        format.json { render json: @symbol, status: :created, location: @symbol }
      else
        format.html { render action: "new" }
        format.json { render json: @symbol.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /symbols/1
  # PUT /symbols/1.json
  def update
    @symbol = Symbol.find(params[:id])

    respond_to do |format|
      if @symbol.update_attributes(params[:symbol])
        format.html { redirect_to @symbol, notice: 'Symbol was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @symbol.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /symbols/1
  # DELETE /symbols/1.json
  def destroy
    @symbol = Symbol.find(params[:id])
    @symbol.destroy

    respond_to do |format|
      format.html { redirect_to symbols_url }
      format.json { head :no_content }
    end
  end
end
