use aiken/crypto.{VerificationKey}
use cardano/assets.{AssetName, PolicyId}
use sundae/multisig.{MultisigScript}

pub type Action {
  Genesis
  Recreate
  ChangeAdmin
  SingletonWithdraw(VerificationKey)
}

pub type MerkleOracleRedeemer {
  action: Action,
}

pub type MerkleOracleDatum {
  admin_singleton_policy_id: PolicyId,
  admin_singleton_asset_name: AssetName,
  merkle_root: ByteArray,
  ipfs_cid: ByteArray,
  created_at: Int,
}

pub type MultisigDatum {
  threshold_amount: Int,
  signatures: List<MultisigScript>,
}

pub type TimeRange {
  lower_bound: Int,
  upper_bound: Int,
}
