class CreateTechnicals < ActiveRecord::Migration
  def change
    create_table :technicals do |t|
      t.string :indicator_type
      t.date :date
      t.integer :value
      t.references :ticker

      t.timestamps
    end
    add_index :technicals, :ticker_id
  end
end
