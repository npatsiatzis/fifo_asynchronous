`default_nettype none

module async_fifo
    #
    (
        parameter int g_width /*verilator public*/ = 8,
        parameter int g_depth = 6
    )

    (
        input logic i_clkW,
        input logic i_arstnW,
        input logic i_wren,
        input logic [g_width - 1 : 0] i_dataW,

        input logic i_clkR,
        input logic i_arstnR,
        input logic i_ren,

        output logic [g_width - 1 : 0] o_dataR,
        output logic o_empty,
        output logic o_full
    );

    logic [g_width - 1 : 0] mem [2**g_depth];

    // control pointers. 1 extra bit than what required to address the memory to
    // calculate the full/empty conditions
    logic [g_depth : 0] gray_r, gray_r_next;
    logic [g_depth : 0] gray_w, gray_w_next;
    logic [g_depth : 0] bin_r, bin_r_next;
    logic [g_depth : 0] bin_w, bin_w_next;
    // memory address pointers (used to address memory for write/read operations)
    // exclude MSB of control pointers
    logic [g_depth - 1 : 0] addr_w, addr_r;

    // 2ff synchronization of gray pointers between read and write clock domains
    logic [g_depth : 0] gray_r_2_w [2];
    logic [g_depth : 0] gray_w_2_r [2];

    logic o_empty_next;
    logic o_full_next;

    /* can use lint_off UNUSEDSIGNAL */
    logic f_wr_done, f_rd_done;
    /* can use lint_on UNUSEDSIGNAL */

    // WRITE DOMAIN

    // cross the gray-encoded read address pointer over to the write domain
    always_ff @(posedge i_clkW or negedge i_arstnW) begin : cdc_r_2_w
        if(!i_arstnW) begin
            `ifdef ICARUS   
                gray_r_2_w[0] <= 0;
                gray_r_2_w[1] <= 1;
            `else
                gray_r_2_w <= '{default : '0};
            `endif
        end else begin
            gray_r_2_w[1] <= gray_r_2_w[0];
            gray_r_2_w[0] <= gray_r;
        end
    end

    assign bin_w_next = (i_wren && !o_full) ? bin_w + 1 : bin_w;
    assign gray_w_next = (bin_w_next >> 1) ^ bin_w_next;
    assign addr_w = bin_w[g_depth -1 : 0];


    always_ff @(posedge i_clkW or negedge i_arstnW) begin : manage_w_addr
        if(!i_arstnW) begin
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
    assign o_full_next = (gray_w_next == {~gray_r_2_w[1][g_depth],
            ~gray_r_2_w[1][g_depth - 1],gray_r_2_w[1][g_depth -2 : 0]}) ? 1'b1 : 1'b0;

    // always_comb begin : calc_full
    //     if (gray_w_next == {~gray_r_2_w[1][g_depth],
    //         ~gray_r_2_w[1][g_depth - 1],gray_r_2_w[1][g_depth -2 : 0]})
    //         o_full_next = 1'b1;
    //     else
    //         o_full_next = 1'b0;

    // end

    always_ff @(posedge i_clkW or negedge i_arstnW) begin : reg_full
        if(!i_arstnW) begin
            o_full <= '0;
        end else begin
            o_full <= o_full_next;
        end
    end

    // FIFO write operation

    always_ff @(posedge i_clkW or negedge i_arstnW) begin : mem_write
        f_wr_done <= 1'b0;
        if (i_wren && !o_full)
            mem[addr_w] <= i_dataW;
            f_wr_done <= 1'b1;
    end

    // READ DOMAIN

    always_ff @(posedge i_clkR or negedge i_arstnR) begin : cdc_w_2_r
        if(!i_arstnR) begin
            `ifdef ICARUS
                gray_w_2_r[0] <= 0;
                gray_w_2_r[1] <= 0;
            `else
                gray_w_2_r <= '{default : '0};
            `endif
        end else begin
            gray_w_2_r[1] <= gray_w_2_r[0];
            gray_w_2_r[0] <= gray_w;
        end
    end

    assign bin_r_next = (i_ren && !o_empty) ? bin_r + 1 : bin_r;
    assign gray_r_next  = (bin_r_next >> 1) ^ bin_r_next;
    assign addr_r = bin_r[g_depth - 1 : 0];


    always_ff @(posedge i_clkR or negedge i_arstnR) begin : manage_r_addr
        if(~i_arstnR) begin
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

    always_ff @(posedge i_clkR or negedge i_arstnR) begin : reg_empty
        if(!i_arstnR) begin
            o_empty <= 1'b1;
        end else begin
            o_empty <= o_empty_next;
        end
    end

    always_ff @(posedge i_clkR or negedge i_arstnR) begin : mem_read
        if(!i_arstnR) begin
            o_dataR <= '0;
            f_rd_done <= 1'b0;
        end else begin
            f_rd_done <= 1'b0;
            if (i_ren && !o_empty) begin
                o_dataR <= mem[addr_r];
                f_rd_done <= 1'b1;
            end
        end
    end


    `ifdef WAVEFORM
        initial begin
            // Dump waves
            $dumpfile("dump.vcd");
            $dumpvars(0, async_fifo);
        end
    `endif

endmodule : async_fifo
