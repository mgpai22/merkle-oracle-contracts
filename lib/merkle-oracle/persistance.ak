use aiken/collection/list
use cardano/address.{Script}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{Output, OutputReference, Transaction}
use merkle_oracle/constants.{contract_output_index}
use merkle_oracle/types.{
  ChangeAdmin, MerkleOracleDatum, MerkleOracleRedeemer, Recreate,
}
use merkle_oracle/utils.{
  expect_and_get_single_token, get_current_time, get_inline_datum,
}

pub fn valid_persistance(
  tx: Transaction,
  my_output_reference: OutputReference,
  singleton_policy_id: PolicyId,
  asset_name: AssetName,
  redeemer: MerkleOracleRedeemer,
  datum: MerkleOracleDatum,
) -> Bool {
  expect Some(self) =
    tx.inputs
      |> transaction.find_input(my_output_reference)

  expect Script(self_script) = self.output.address.payment_credential

  expect Some(recreated_self_box) = tx.outputs |> list.at(contract_output_index)

  expect Script(recreated_self_script) =
    recreated_self_box.address.payment_credential

  expect self_script == recreated_self_script

  let (retrived_policy, retrived_asset_name, retrived_qty) =
    expect_and_get_single_token(recreated_self_box.value)

  when redeemer.action is {
    Recreate -> and {
        (retrived_policy == singleton_policy_id)?,
        (retrived_asset_name == asset_name)?,
        (retrived_qty == 1)?,
        valid_recreate_datum(
          datum,
          recreated_self_box,
          get_current_time(tx.validity_range),
        ),
      }
    ChangeAdmin -> valid_change_admin_datum(datum, recreated_self_box)
    _ -> False
  }
}

fn valid_change_admin_datum(
  input_datum: MerkleOracleDatum,
  output: Output,
) -> Bool {
  expect MerkleOracleDatum { merkle_root, ipfs_cid, created_at, .. }: MerkleOracleDatum =
    get_inline_datum(output.datum)

  and {
    (merkle_root == input_datum.merkle_root)?,
    (ipfs_cid == input_datum.ipfs_cid)?,
    (created_at == input_datum.created_at)?,
  }
}

fn valid_recreate_datum(
  input_datum: MerkleOracleDatum,
  output: Output,
  current_time: Int,
) -> Bool {
  expect MerkleOracleDatum {
    admin_singleton_policy_id,
    admin_singleton_asset_name,
    created_at,
    ..
  }: MerkleOracleDatum = get_inline_datum(output.datum)

  and {
    (admin_singleton_policy_id == input_datum.admin_singleton_policy_id)?,
    (admin_singleton_asset_name == input_datum.admin_singleton_asset_name)?,
    (created_at == current_time)?,
  }
}
