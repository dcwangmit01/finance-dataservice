class CreateTechnicals < ActiveRecord::Migration
  def change
    create_table :technicals do |t|
      t.references :ticker
      t.string :indicator_type
      t.integer :value
      t.date :date
      t.timestamps
    end
    add_index :technicals, :ticker_id
  end
end
