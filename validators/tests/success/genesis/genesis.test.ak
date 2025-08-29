use aiken/interval.{Finite, Interval, IntervalBound}
use cardano/address.{Address, Script, VerificationKey}
use cardano/assets.{add, from_lovelace, zero}
use cardano/transaction.{
  InlineDatum, Input, NoDatum, Output, OutputReference, Transaction,
}
use merkle_oracle/merkle_oracle_validator.{merkle_oracle_mint_validator}
use merkle_oracle/tests/global_test_variables.{
  alice_address_hash, one_ada, oracle_contract_hash, oracle_singleton_asset_name,
}
use merkle_oracle/types.{Genesis, MerkleOracleDatum, MerkleOracleRedeemer}

// Test for sucess case of genesis
test create_genesis() {
  let current_time = 1
  let later_time = current_time

  let owner_address =
    Address {
      payment_credential: VerificationKey(alice_address_hash),
      stake_credential: None,
    }

  let owner_input_output_ref =
    OutputReference {
      transaction_id: #"dcb9788326b92481d5bb0e1de8d85ecfec619947880c43d422aa0a672c79dc2c",
      output_index: 0,
    }

  let owner_input_utxo_details =
    Output {
      address: owner_address,
      value: from_lovelace(one_ada),
      datum: NoDatum,
      reference_script: None,
    }

  let owner_input =
    Input {
      output_reference: owner_input_output_ref,
      output: owner_input_utxo_details,
    }

  let oracle_output_datum =
    MerkleOracleDatum {
      merkle_root: #"",
      ipfs_cid: #"",
      admin_singleton_policy_id: #"9622b0ef9aa1bd62d1c524d0e5e494aff7e75c5678f55f55e2115690",
      admin_singleton_asset_name: #"6d756c74697369675f73696e676c65746f6e",
      created_at: current_time,
    }

  let oracle_output_datum_casted: Data = oracle_output_datum

  let oracle_singleton_policy_id = oracle_contract_hash

  let oracle_output =
    Output {
      address: Address {
        payment_credential: Script(oracle_contract_hash),
        stake_credential: None,
      },
      value: from_lovelace(one_ada)
        |> add(oracle_singleton_policy_id, oracle_singleton_asset_name, 1),
      datum: InlineDatum(oracle_output_datum_casted),
      reference_script: None,
    }

  let tx =
    transaction.placeholder
      |> fn(transaction) {
          Transaction {
            ..transaction,
            inputs: [owner_input],
            outputs: [oracle_output],
            mint: zero
              |> add(oracle_singleton_policy_id, oracle_singleton_asset_name, 1),
            validity_range: Interval {
              lower_bound: IntervalBound {
                bound_type: Finite(current_time),
                is_inclusive: True,
              },
              upper_bound: IntervalBound {
                bound_type: Finite(later_time),
                is_inclusive: True,
              },
            },
          }
        }

  let redeemer = MerkleOracleRedeemer { action: Genesis }

  merkle_oracle_mint_validator(
    oracle_singleton_asset_name,
    redeemer,
    tx,
    oracle_singleton_policy_id,
    owner_input_output_ref,
  )
}
