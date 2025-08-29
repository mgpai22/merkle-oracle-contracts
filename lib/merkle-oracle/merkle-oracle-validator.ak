use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use merkle_oracle/constants.{contract_output_index}
use merkle_oracle/multisig.{valid_multisig}
use merkle_oracle/persistance.{valid_persistance}
use merkle_oracle/singleton_withdraw.{valid_singleton_withdraw}
use merkle_oracle/types.{
  ChangeAdmin, Genesis, MerkleOracleDatum, MerkleOracleRedeemer, Recreate,
  SingletonWithdraw,
}
use merkle_oracle/utils.{expect_and_get_single_token, get_current_time}

pub fn merkle_oracle_validator(
  datum: MerkleOracleDatum,
  redeemer: MerkleOracleRedeemer,
  tx: Transaction,
  my_output_reference: OutputReference,
  singleton_asset_name: AssetName,
) -> Bool {
  expect Some(self) =
    tx.inputs
      |> transaction.find_input(my_output_reference)

  expect Script(self_script) = self.output.address.payment_credential

  when redeemer.action is {
    Recreate -> and {
        valid_persistance(
          tx,
          my_output_reference,
          self_script,
          singleton_asset_name,
          redeemer,
          datum,
        ),
        valid_multisig(datum, tx),
      }

    ChangeAdmin -> and {
        valid_persistance(
          tx,
          my_output_reference,
          self_script,
          singleton_asset_name,
          redeemer,
          datum,
        ),
        valid_multisig(datum, tx),
      }

    SingletonWithdraw(_) -> and {
        valid_singleton_withdraw(
          tx,
          self_script,
          singleton_asset_name,
          redeemer,
        ),
        valid_multisig(datum, tx),
      }

    _ -> False
  }
}

pub fn merkle_oracle_mint_validator(
  singleton_asset_name: AssetName,
  redeemer: MerkleOracleRedeemer,
  tx: Transaction,
  self_policy_id: PolicyId,
  utxo_ref: OutputReference,
) -> Bool {
  let Transaction { inputs, mint, .. } = tx

  when redeemer.action is {
    Genesis -> {
      expect list.any(inputs, fn(input) { input.output_reference == utxo_ref })

      expect Some(output) = tx.outputs |> list.at(contract_output_index)

      expect Script(output_script) = output.address.payment_credential
      expect output_script == self_policy_id

      let (policy_from_mint, asset_name_from_mint, qty_from_mint) =
        expect_and_get_single_token(mint)

      expect
        policy_from_mint == self_policy_id && asset_name_from_mint == singleton_asset_name && qty_from_mint == 1

      let (policy_from_output, asset_name_from_output, qty_from_output) =
        expect_and_get_single_token(output.value)

      expect
        policy_from_output == self_policy_id && asset_name_from_output == singleton_asset_name && qty_from_output == 1

      expect InlineDatum(output_datum) = output.datum

      expect MerkleOracleDatum { created_at, .. }: MerkleOracleDatum =
        output_datum
      expect created_at == get_current_time(tx.validity_range)

      True
    }
    _ -> False
  }
}
