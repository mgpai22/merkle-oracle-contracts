use cardano/address.{VerificationKey}
use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{Output, Transaction}
use merkle_oracle/types.{MerkleOracleRedeemer, SingletonWithdraw}
use merkle_oracle/utils.{filter_outputs_by_token}

pub fn valid_singleton_withdraw(
  tx: Transaction,
  singleton_policy_id: PolicyId,
  singleton_asset_name: AssetName,
  redeemer: MerkleOracleRedeemer,
) -> Bool {
  expect [recipient_output]: List<Output> =
    filter_outputs_by_token(
      tx.outputs,
      singleton_policy_id,
      singleton_asset_name,
    )

  when redeemer.action is {
    SingletonWithdraw(recipient_vkey) ->
      (recipient_output.address.payment_credential == VerificationKey(
        recipient_vkey,
      ))?

    _ -> False
  }
}
