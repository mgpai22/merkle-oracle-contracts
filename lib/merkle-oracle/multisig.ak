use cardano/transaction.{Input, Transaction}
use merkle_oracle/types.{MerkleOracleDatum, MultisigDatum}
use merkle_oracle/utils.{filter_inputs_by_token, get_inline_datum}
use sundae/multisig.{AtLeast, satisfied}

pub fn valid_multisig(datum: MerkleOracleDatum, tx: Transaction) -> Bool {
  expect [multisig_input]: List<Input> =
    filter_inputs_by_token(
      tx.reference_inputs,
      datum.admin_singleton_policy_id,
      datum.admin_singleton_asset_name,
    )

  expect MultisigDatum { threshold_amount, signatures }: MultisigDatum =
    get_inline_datum(multisig_input.output.datum)

  satisfied(
    AtLeast { required: threshold_amount, scripts: signatures },
    tx.extra_signatories,
    tx.validity_range,
    tx.withdrawals,
  )?
}
