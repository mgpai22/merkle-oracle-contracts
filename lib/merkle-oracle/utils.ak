use aiken/collection/dict
use aiken/collection/list.{filter}
use aiken/interval.{Finite}
use cardano/assets.{AssetName, PolicyId, Value, quantity_of}
use cardano/transaction.{Datum, InlineDatum, Input, Output, ValidityRange}
use merkle_oracle/types.{TimeRange}

pub fn expect_single_token(v: Value) -> Void {
  expect [Pair(_, tn_qty_pairs)] =
    v
      |> assets.to_dict
      |> dict.delete(assets.ada_policy_id)
      |> dict.to_pairs
  expect [Pair(_, _)] = tn_qty_pairs |> dict.to_pairs
}

pub fn expect_and_get_single_token(v: Value) -> (PolicyId, AssetName, Int) {
  expect [Pair(sym, tn_qty_pairs)] =
    v
      |> assets.to_dict
      |> dict.delete(assets.ada_policy_id)
      |> dict.to_pairs
  expect [Pair(tn, qty)] = tn_qty_pairs |> dict.to_pairs
  (sym, tn, qty)
}

pub fn get_inline_datum(datum: Datum) -> Data {
  when datum is {
    InlineDatum(d) -> d
    _ -> fail @"Expected Inline Datum"
  }
}

pub fn filter_inputs_by_token(
  inputs: List<Input>,
  policy_id: PolicyId,
  asset_name: AssetName,
) {
  inputs
    |> filter(fn(i) { quantity_of(i.output.value, policy_id, asset_name) > 0 })
}

pub fn filter_outputs_by_token(
  outputs: List<Output>,
  policy_id: PolicyId,
  asset_name: AssetName,
) {
  outputs
    |> filter(fn(i) { quantity_of(i.value, policy_id, asset_name) > 0 })
}

pub fn get_time_range(validity_range: ValidityRange) -> TimeRange {
  when
    (
      validity_range.lower_bound.bound_type,
      validity_range.upper_bound.bound_type,
    )
  is {
    (Finite(lower), Finite(upper)) ->
      TimeRange { lower_bound: lower, upper_bound: upper }
    _ -> fail @"Invalid Validity Range Bounds"
  }
}

// 5 min
pub const max_time_range = 300000

pub fn validate_time_range(time_range: TimeRange) -> Bool {
  and {
    // ensure range isn't too wide
    (time_range.upper_bound - time_range.lower_bound <= max_time_range)?,
    // ensure lower bound isn't negative
    (time_range.lower_bound > 0)?,
  }
}

pub fn get_current_time(validity_range: ValidityRange) -> Int {
  let time_range = get_time_range(validity_range)
  when validate_time_range(time_range) is {
    True -> ( time_range.upper_bound + time_range.lower_bound ) / 2
    False -> fail @"Invalid Time Range"
  }
}
