require "test_helper"

class SuivisCSVRowTest < Minitest::Test

  def setup
    super
  end
  def teardown
  end

  def suivis_csv
    @suivis_csv ||= file_avec_suivi.suivi
  end

  def file_avec_suivi
    @file_avec_suivi ||= Suivi::File.new(path_avec_suivi)
  end
  def path_avec_suivi
    @path_avec_suivi ||= File.join(ASSETS_FOLDER,'files','good','ok.csv')
  end


  # --- LES TESTS ---

  def test_on_peut_charger_toutes_les_rangees_de_suivi
    allrows = suivis_csv.load
    expected = 8
    assert_equal(expected, allrows.count, "Il devrait y avoir #{expected} transactions. Il y en a #{allrows.count}…")

    prem_trans = allrows.first

    assert_respond_to prem_trans, :id
    assert_respond_to prem_trans, :client_id
    assert_respond_to prem_trans, :transaction_id
    assert_respond_to prem_trans, :transaction_type
    assert_respond_to prem_trans, :produits_ids
    assert_respond_to prem_trans, :produits

  end

end #/class Minitest
