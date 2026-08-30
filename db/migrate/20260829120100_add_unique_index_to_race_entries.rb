class AddUniqueIndexToRaceEntries < ActiveRecord::Migration[7.0]
  def change
    add_index :race_entries, [:race_edition_id, :racer_id], unique: true
  end
end
