class ApplicationController < ActionController::Base
  protect_from_forgery

  
  private
  def __export(models)
    
    respond_to do |format|
      format.json { render json: models }
      format.xml { render xml: models }
      format.csv do 
        csv_string = CSV.generate do |csv| 
          first = true
          models.each do |model| 
            if (first == true)
              # header row 
              csv << model.attribute_names
              first = false
            end
            # data rows 
            csv << model.attributes.values
          end 
        end 
        # send it to the browser
        send_data csv_string,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => "attachment; filename=data.csv"
      end 
    end
  end

end
