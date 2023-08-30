`default_nettype none

module async_fifo
    #
    (
        parameter int G_WIDTH /*verilator public*/ = 8,
        parameter int G_DEPTH = 4
    )

    (
        input logic i_clk_w,
        input logic i_arstN_w,
        input logic i_wren_w,
        input logic [G_WIDTH - 1 : 0] i_data_w,

        input logic i_clk_r,
        input logic i_arstN_r,
        input logic i_ren_r,

        output logic [G_WIDTH - 1 : 0] o_data,
        output logic o_empty,
        output logic o_full
    );

    logic [G_WIDTH - 1 : 0] mem [2**G_DEPTH];

    // control pointers. 1 extra bit than what required to address the memory to
    // calculate the full/empty conditions
    logic [G_DEPTH : 0] gray_r, gray_r_next;
    logic [G_DEPTH : 0] gray_w, gray_w_next;
    logic [G_DEPTH : 0] bin_r, bin_r_next;
    logic [G_DEPTH : 0] bin_w, bin_w_next;
    // memory address pointers (used to address memory for write/read operations)
    // exclude MSB of control pointers
    logic [G_DEPTH - 1 : 0] addr_w, addr_r;

    // 2ff synchronization of gray pointers between read and write clock domains
    logic [G_DEPTH : 0] gray_r_2_w [2];
    logic [G_DEPTH : 0] gray_w_2_r [2];

    logic o_empty_next;
    logic o_full_next;

    // WRITE DOMAIN

    // cross the gray-encoded read address pointer over to the write domain
    always_ff @(posedge i_clk_w or negedge i_arstN_w) begin : cdc_r_2_w
        if(!i_arstN_w) begin
            gray_r_2_w <= '{default : '0};
        end else begin
            gray_r_2_w[1] <= gray_r_2_w[0];
            gray_r_2_w[0] <= gray_r;
        end
    end

    assign bin_w_next = (i_wren_w && !o_full) ? bin_w + 1 : bin_w;
    assign gray_w_next = (bin_w_next >> 1) ^ bin_w_next;
    assign addr_w = bin_w[G_DEPTH -1 : 0];


    always_ff @(posedge i_clk_w or negedge i_arstN_w) begin : manage_w_addr
        if(!i_arstN_w) begin
            gray_w <= '0;
            bin_w <= '0;
        end else begin
            gray_w <= gray_w_next;
            bin_w <= bin_w_next;
        end
    end

    // calculate if FIFO will be full on next clock cycle
    // continous assign is equivalent in terms of funtionality, but it does not 
    // throw the "ALWCOMBORDER" warning with verilator
    assign o_full_next = (gray_w_next == {~gray_r_2_w[1][G_DEPTH],
            ~gray_r_2_w[1][G_DEPTH - 1],gray_r_2_w[1][G_DEPTH -2 : 0]}) ? 1'b1 : 1'b0;

    // always_comb begin : calc_full
    //     if (gray_w_next == {~gray_r_2_w[1][G_DEPTH],
    //         ~gray_r_2_w[1][G_DEPTH - 1],gray_r_2_w[1][G_DEPTH -2 : 0]})
    //         o_full_next = 1'b1;
    //     else
    //         o_full_next = 1'b0;

    // end

    always_ff @(posedge i_clk_w or negedge i_arstN_w) begin : reg_full
        if(!i_arstN_w) begin
            o_full <= '0;
        end else begin
            o_full <= o_full_next;
        end
    end

    // FIFO write operation

    always_ff @(posedge i_clk_w or negedge i_arstN_w) begin : mem_write
        if (i_wren_w && !o_full)
            mem[addr_w] <= i_data_w;
    end

    // READ DOMAIN

    always_ff @(posedge i_clk_r or negedge i_arstN_r) begin : cdc_w_2_r
        if(!i_arstN_r) begin
            gray_w_2_r <= '{default : '0};
        end else begin
            gray_w_2_r[1] <= gray_w_2_r[0];
            gray_w_2_r[0] <= gray_w;
        end
    end

    assign bin_r_next = (i_ren_r && !o_empty) ? bin_r + 1 : bin_r;
    assign gray_r_next  = (bin_r_next >> 1) ^ bin_r_next;
    assign addr_r = bin_r[G_DEPTH - 1 : 0];


    always_ff @(posedge i_clk_r or negedge i_arstN_r) begin : manage_r_addr
        if(~i_arstN_r) begin
            gray_r <= '0;
            bin_r <= '0;
        end else begin
            gray_r <= gray_r_next;
            bin_r <= bin_r_next;
        end
    end

    // determine if FIFO will be empty on the next clock
    assign o_empty_next = (gray_r_next == gray_w_2_r[1]) ? 1'b1 : 1'b0;

    // always_comb begin : calc_empty
    //     if(gray_r_next == gray_w_2_r[1])
    //         o_empty_next = 1'b1;
    //     else
    //         o_empty_next = 1'b0;
    // end

    always_ff @(posedge i_clk_r or negedge i_arstN_r) begin : reg_empty
        if(!i_arstN_r) begin
            o_empty <= 1'b1;
        end else begin
            o_empty <= o_empty_next;
        end
    end

    always_ff @(posedge i_clk_r or negedge i_arstN_r) begin : mem_read
        if(!i_arstN_r) begin
            o_data <= '0;
        end else begin
            if (i_ren_r && !o_empty)
                o_data <= mem[addr_r];
        end
    end

endmodule : async_fifo
