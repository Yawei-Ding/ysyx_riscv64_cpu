interface axi4_if;
  parameter ADDR_W = 32;
  parameter DATA_W = 64;
  parameter ID_W   = 4;
  parameter USER_W = 1;

  localparam STRB_W = DATA_W/8;

  // 1. addr write channel:
  logic                   aw_ready  ;
  logic                   aw_valid  ;
  logic   [ADDR_W-1:0]    aw_addr   ;
  logic   [2:0]           aw_prot   ;
  logic   [7:0]           aw_len    ;
  logic   [2:0]           aw_size   ;
  logic   [1:0]           aw_burst  ;
  logic                   aw_lock   ;
  logic   [3:0]           aw_cache  ;
  logic   [3:0]           aw_qos    ;
  logic   [ID_W-1:0]      aw_id     ;
  logic   [USER_W-1:0]    aw_user   ;
  logic   [3:0]           aw_region ;

  // 2. data write channel:
  logic                   w_valid   ;
  logic   [DATA_W-1:0]    w_data    ;
  logic   [STRB_W-1:0]    w_strb    ;
  logic                   w_last    ;
  logic                   w_ready   ;
  logic   [USER_W-1:0]    w_user    ; // duo le yige.

  // 3. write response channel:
  logic   [1:0]           b_resp    ;
  logic   [ID_W-1:0]      b_id      ;
  logic                   b_ready   ;
  logic                   b_valid   ;
  logic   [USER_W-1:0]    b_user    ;

  // 4. addr read channel:
  logic                   ar_ready  ;
  logic                   ar_valid  ;
  logic   [ADDR_W-1:0]    ar_addr   ;
  logic   [2:0]           ar_prot   ;
  logic   [7:0]           ar_len    ;
  logic   [2:0]           ar_size   ;
  logic   [1:0]           ar_burst  ;
  logic                   ar_lock   ;
  logic   [3:0]           ar_cache  ;
  logic   [3:0]           ar_qos    ;
  logic   [ID_W-1:0]      ar_id     ;
  logic   [USER_W-1:0]    ar_user   ;
  logic   [3:0]           ar_region ;

  // 5. data read channel:
  logic   [DATA_W-1:0]    r_data    ;
  logic   [1:0]           r_resp    ;
  logic                   r_last    ;
  logic   [ID_W-1:0]      r_id      ;
  logic                   r_ready   ;
  logic                   r_valid   ;
  logic   [USER_W-1:0]    r_user    ;

  modport Master
  (
    output aw_valid, output aw_addr, output aw_prot,  output aw_region,
    output aw_len,   output aw_size, output aw_burst, output aw_lock,
    output aw_cache, output aw_qos,  output aw_id,    output aw_user,
    input  aw_ready,

    output ar_valid, output ar_addr, output ar_prot,  output ar_region,
    output ar_len,   output ar_size, output ar_burst, output ar_lock,
    output ar_cache, output ar_qos,  output ar_id,    output ar_user,
    input  ar_ready,

    output w_valid,  output w_data,  output w_strb,   output w_last,
    output w_user,   input  w_ready,

    input  r_valid,  input  r_data,  input  r_resp,   input  r_last,
    input  r_id,     input  r_user,  output r_ready,

    input  b_valid,  input  b_resp,  input  b_id,     input  b_user,
    output b_ready
  );

  modport Slave
  (
    input  aw_valid, input  aw_addr, input  aw_prot,  input  aw_region,
    input  aw_len,   input  aw_size, input  aw_burst, input  aw_lock,
    input  aw_cache, input  aw_qos,  input  aw_id,    input  aw_user,
    output aw_ready,

    input  ar_valid, input  ar_addr, input  ar_prot,  input  ar_region,
    input  ar_len,   input  ar_size, input  ar_burst, input  ar_lock,
    input  ar_cache, input  ar_qos,  input  ar_id,    input  ar_user,
    output ar_ready,

    input  w_valid,  input  w_data,  input  w_strb,   input  w_last,
    input  w_user,   output w_ready,

    output r_valid,  output r_data,  output r_resp,   output r_last,
    output r_id,     output r_user,  input  r_ready,

    output b_valid,  output b_resp,  output b_id,     output b_user,
    input  b_ready
  );

endinterface
