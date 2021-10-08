#include "./ITokenFA2.ligo"

type transfer_fa2_type  is list (transfer_param)
type transfer_fa12_type is michelson_pair(address, "from", michelson_pair(address, "to", nat, "value"), "")
type entry_fa12_type    is TransferTypeFA12 of transfer_fa12_type
type entry_fa2_type     is TransferTypeFA2 of transfer_fa2_type
type bal_fa12_type      is address * contract(nat)
type balance_fa12_type  is BalanceOfTypeFA12 of bal_fa12_type
type balance_fa2_type   is BalanceOfTypeFA2 of bal_fa2_type

type fa2_token_type     is record [
  token_address           : address; (* token A address *)
  token_id                : nat; (* token A identifier *)
]

type token_type        is
| Fa12                    of address
| Fa2                     of fa2_token_type


type pair_type          is record [
  // exchange_admin          : address;
  initial_A               : nat; (* Constant that describes A constant *)
  initial_A_time          : timestamp;
  tokens_count            : nat; (* from 2 to 4 tokens at one exchange pool *)
  tokens                  : tokens_type; (* list of exchange tokens *)
  dev_balances            : map(nat, nat); (* list of admin balances of each token in pool *)
  pools                   : map(nat, nat); (* list of token reserves in the pool *)
  virtual_pools           : map(nat, nat);
  future_A                : nat;
  future_A_time           : timestamp;

  // proxy_enabled           : bool;
  proxy_contract          : option(address);
  proxy_limits            : map(nat, nat);

  total_supply            : nat; (* total shares count *)
]

type tokens_type        is map(nat, token_type); (* NOTE: maximum 4 tokens from 0 to 3 *)

type fees_storage_type  is record[
  lp_fee                  : nat;
  stakers_fee             : nat;
  ref_fee                 : nat;
  dev_fee                 : nat;
]

type storage_type       is record [
  admin                   : address;
  managers                : set(address);
  dev_address             : address;
  fee                     : fees_storage_type;
  is_public_init          : bool;
  reward_rate             : nat;
  // entered                 : bool; (* reentrancy protection *)
  pairs_count             : nat; (* total pools count *)
  tokens                  : big_map(nat, tokens_type); (* all the tokens list *)
  token_to_id             : big_map(bytes, nat); (* all the tokens list *)
  pairs                   : big_map(nat, pair_type); (* pair info per token id *)
  ledger                  : big_map((address * nat), account_info); (* account info per address *)
]

// type swap_type          is
// | A_to_b (* exchange token A to token B *)
// | B_to_a (* exchange token B to token A *)

// type swap_slice_type    is record [
//   pair_id                 : nat; (* pair identifier *)
//   operation               : swap_type; (* exchange operation *)
// ]

// type swap_side_type     is record [
//   pool                    : nat; (* pair identifier*)
//   token                   : token_type; (* token standard *)
// ]

// type swap_data_type     is record [
//   to_                     : swap_side_type; (* info about sold asset *)
//   from_                   : swap_side_type; (* info about bought asset *)
// ]

// type tmp_swap_type      is record [
//   s                       : storage_type; (* storage_type state *)
//   amount_in               : nat; (* amount of tokens to be sold *)
//   token_in                : token_type; (* type of sold token *)
//   operation               : option(operation); (* exchange operation type *)
//   receiver                : address; (* address of the receiver *)
// ]

type swap_type         is [@layout:comb] record [
  asset_id_in             : nat;
  amount_in               : nat; (* amount of tokens to be exchanged *)
  asset_id_out            : nat;
  min_amount_out          : nat; (* min amount of tokens received to accept exchange *)
  receiver                : address; (* tokens receiver *)
]

type input_tokens  is [@layout:comb] record [
  asset                  : token_type; (* exchange pair info *)
  in_amount              : nat; (* amount of tokens, where `index of value` == `index of token` to be invested *)
]

type initialize_params  is [@layout:comb] record [
  a_constant              : nat;
  n_tokens                : nat;
  input_tokens            : map(nat, input_tokens); (* amount of tokens, where `index of value` == `index of token` to be invested *)
]

type add_rem_man_params is [@layout:comb] record [
  add                     : bool;
  candidate               : address;
]

type invest_type        is [@layout:comb] record [
  pair_id                 : nat; (* pair identifier *)
  shares                  : nat; (* the amount of shares to receive *)
  in_amounts              : map(nat, nat); (* amount of tokens, where `index of value` == `index of token` to be invested *)
]

type divest_type        is [@layout:comb] record [
  pair_id                 : nat; (* pair identifier *)
  min_amounts_out         : map(nat, nat); (* min amount of tokens, where `index of value` == `index of token` to be received to accept the divestment *)
  shares                  : nat; (* amount of shares to be burnt *)
]

type reserves_type      is record [
  receiver                : contract(map(nat, nat)); (* response receiver *)
  pair_id                 : nat; (* pair identifier *)
]

type total_supply_type  is record [
  receiver                : contract(nat); (* response receiver *)
  pair_id                 : nat; (* pair identifier *)
]

type action_type        is
(* Base actions *)
| AddPair                 of initialize_params  (* sets initial liquidity *)
| Swap                    of swap_type          (* exchanges token to another token and sends them to receiver *)
| Invest                  of invest_type        (* mints min shares after investing tokens *)
| Divest                  of divest_type        (* burns shares and sends tokens to the owner *)
(* Custom actions *)
| Invest_one              of invest_one_coin_type
| Divest_one              of divest_one_coin_type
(* Admin actions *)
| Claim_admin_rewards     of claim_adm_rewards_type
(* VIEWS *)
| Get_reserves            of reserves_type      (* returns the underlying token reserves *)
| Total_supply            of total_supply_type  (* returns totalSupply of LP tokens *)
| Min_received            of min_received_type  (* returns minReceived tokens after swapping *)
| Tokens_per_shares       of tps_type           (* returns map of tokens amounts to recieve 1 LP *)
| Price_cummulative       of price_cumm_type    (* returns price cumulative and timestamp per block *)
| Calc_divest_one_coin    of calc_divest_one_coin
| Get_dy                  of get_dy_type        (* returns the current output dy given input dx *)
| Get_a                   of get_a_type

type transfer_type      is list (transfer_param)
type operator_type      is list (update_operator_param)

type token_action_type  is
| ITransfer               of transfer_type (* transfer asset from one account to another *)
| IBalance_of             of bal_fa2_type (* returns the balance of the account *)
| IUpdate_operators       of operator_type (* updates the token operators *)

type return_type        is list (operation) * storage_type
type dex_func_type      is (action_type * storage_type) -> return_type
type token_func_type    is (token_action_type * storage_type) -> return_type

type set_token_func_type is record [
  func                    : token_func_type; (* code of the function *)
  index                   : nat; (* the key in functions map *)
]

type set_dex_func_type  is record [
  func                    : dex_func_type; (* code of the function *)
  index                   : nat; (* the key in functions map *)
]

type full_action_type   is
| Use_dex                 of action_type
| Use_token               of token_action_type
// | Transfer                of transfer_type (* transfer asset from one account to another *)
// | Balance_of              of bal_fa2_type (* returns the balance of the account *)
// | Update_operators        of operator_type (* updates the token operators *)
// | Get_reserves            of reserves_type (* returns the underlying token reserves *)
// | Close                   of unit (* entrypoint to prevent reentrancy *)
| SetDexFunction          of set_dex_func_type (* sets the dex specific function. Is used before the whole system is launched *)
| SetTokenFunction        of set_token_func_type (* sets the FA function, is used before the whole system is launched *)
| AddRemManagers          of add_rem_man_params (* adds a manager to manage LP token metadata *)
| Set_dev_address         of address
| Set_reward_rate         of nat
| Set_admin               of address
| Set_public_init         of unit
| Get_fees                of get_fees_type

type full_storage_type  is record [
  storage                 : storage_type; (* real dex storage_type *)
  metadata                : big_map(string, bytes); (* metadata storage_type according to TZIP-016 *)
  dex_lambdas             : big_map(nat, dex_func_type); (* map with exchange-related functions code *)
  token_lambdas           : big_map(nat, token_func_type); (* map with token-related functions code *)
]

type full_return_type   is list (operation) * full_storage_type

// const fee_rate            : nat = 333n;
// const fee_denom           : nat = 1000n;
// const fee_num             : nat = 997n;