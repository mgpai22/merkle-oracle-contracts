use cardano/address.{Address, Script}
use cardano/assets.{add, from_lovelace, zero}
use cardano/transaction.{
  InlineDatum, Input, Output, OutputReference, Transaction,
}
use merkle_oracle/merkle_oracle_validator.{merkle_oracle_validator}
use merkle_oracle/tests/global_test_variables.{
  admin_singleton_asset_name, admin_singleton_policy_id, alice_address_hash,
  bob_address_hash, charlie_address_hash, multisig_contract_hash, one_ada,
  oracle_contract_hash, oracle_singleton_asset_name, oracle_singleton_policy_id,
  threshold_amount,
}
use merkle_oracle/types.{
  ChangeAdmin, MerkleOracleDatum, MerkleOracleRedeemer, MultisigDatum,
}
use sundae/multisig.{Signature}

// Test for success case for change admin
test change_admin() {
  let current_time = 1
  let signatures =
    [
      Signature(alice_address_hash),
      Signature(bob_address_hash),
      Signature(charlie_address_hash),
    ]

  let multisig_input_datum = MultisigDatum { signatures, threshold_amount }

  let multisig_input_datum_casted: Data = multisig_input_datum

  let multisig_input_utxo_details =
    Output {
      address: Address {
        payment_credential: Script(multisig_contract_hash),
        stake_credential: None,
      },
      value: from_lovelace(one_ada)
        |> add(admin_singleton_policy_id, admin_singleton_asset_name, 1),
      datum: InlineDatum(multisig_input_datum_casted),
      reference_script: None,
    }

  let multisig_input_output_ref =
    OutputReference {
      transaction_id: #"dcb9788326b92481d5bb0e1de8d85ecfec619947880c43d422aa0a672c79dc2c",
      output_index: 1,
    }

  let multisig_input =
    Input {
      output_reference: multisig_input_output_ref,
      output: multisig_input_utxo_details,
    }

  let oracle_input_output_ref =
    OutputReference {
      transaction_id: #"dcb9788326b92481d5bb0e1de8d85ecfec619947880c43d422aa0a672c79dc2c",
      output_index: 0,
    }

  let oracle_input_datum =
    MerkleOracleDatum {
      merkle_root: #"",
      ipfs_cid: #"",
      admin_singleton_policy_id,
      admin_singleton_asset_name,
      created_at: current_time,
    }

  let oracle_input_datum_casted: Data = oracle_input_datum
  let oracle_self_input_utxo_details =
    Output {
      address: Address {
        payment_credential: Script(oracle_contract_hash),
        stake_credential: None,
      },
      value: from_lovelace(one_ada)
        |> add(oracle_singleton_policy_id, oracle_singleton_asset_name, 1),
      datum: InlineDatum(oracle_input_datum_casted),
      reference_script: None,
    }

  let oracle_input =
    Input {
      output_reference: oracle_input_output_ref,
      output: oracle_self_input_utxo_details,
    }

  let oracle_output_datum =
    MerkleOracleDatum {
      merkle_root: #"",
      ipfs_cid: #"",
      admin_singleton_policy_id: #"",
      admin_singleton_asset_name: #"",
      created_at: current_time,
    }

  let oracle_output_datum_casted: Data = oracle_output_datum

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

  let redeemer = MerkleOracleRedeemer { action: ChangeAdmin }

  let tx =
    transaction.placeholder
      |> fn(transaction) {
          Transaction {
            ..transaction,
            inputs: [oracle_input],
            reference_inputs: [multisig_input],
            outputs: [oracle_output],
            extra_signatories: [bob_address_hash, alice_address_hash],
            mint: zero,
          }
        }

  merkle_oracle_validator(
    oracle_input_datum,
    redeemer,
    tx,
    oracle_input_output_ref,
    oracle_singleton_asset_name,
  )?
}
