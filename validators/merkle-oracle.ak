use cardano/assets.{AssetName, PolicyId}
use cardano/transaction.{OutputReference, Transaction}
use merkle_oracle/merkle_oracle_validator.{
  merkle_oracle_mint_validator, merkle_oracle_validator,
}
use merkle_oracle/types.{MerkleOracleDatum, MerkleOracleRedeemer}

validator merkle_oracle(
  singleton_asset_name: AssetName,
  utxo_ref: OutputReference,
) {
  spend(
    datum_opt: Option<MerkleOracleDatum>,
    redeemer: MerkleOracleRedeemer,
    output_ref: OutputReference,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt
    merkle_oracle_validator(
      datum,
      redeemer,
      tx,
      output_ref,
      singleton_asset_name,
    )
  }

  mint(redeemer: MerkleOracleRedeemer, policy_id: PolicyId, tx: Transaction) {
    merkle_oracle_mint_validator(
      singleton_asset_name,
      redeemer,
      tx,
      policy_id,
      utxo_ref,
    )?
  }

  else(_) {
    fail
  }
}
