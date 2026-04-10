class AddNextBibNumbersToRaceEditions < ActiveRecord::Migration[7.0]
  def change
    add_column :race_editions, :next_male_bib_number, :integer
    add_column :race_editions, :next_female_bib_number, :integer
    add_column :race_editions, :next_kids_bib_number, :integer
  end
end
