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
    execute <<-SQL
    ALTER TABLE technicals
      DROP PRIMARY KEY, ADD PRIMARY KEY(id,ticker_id);
    SQL
    execute <<-SQL
    ALTER TABLE technicals
      PARTITION BY HASH(ticker_id)
      PARTITIONS 8;
    SQL
  end
  
end
