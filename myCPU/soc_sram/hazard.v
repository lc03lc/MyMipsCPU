`timescale 1ns / 1ps

module hazard(
    // Fetch stage
    output wire stallF,

    // Decode stage
    input wire[4:0] rsD, rtD,
    input wire branchD,
    input wire jrD,
    output wire forwardaD, forwardbD,
    output wire stallD,

    // Execute stage
    input wire[4:0] rsE, rtE,
    input wire[4:0] writeregE,
    input wire regwriteE,
    input wire memtoregE,
    input wire div_stallE,
    output reg[1:0] forwardaE, forwardbE,
    output wire flushD,
    output wire flushE,
    output wire flushM,
    output wire flushW,
    output wire stallE,

    // Memory stage
    input wire[4:0] writeregM,
    input wire regwriteM,
    input wire memtoregM,
    input wire is_exceptM,

    // Write-back stage
    input wire[4:0] writeregW,
    input wire regwriteW
);

wire lwstallD, branchstallD;

// Forwarding sources to D stage (branch equality)
assign forwardaD = (rsD != 0 & rsD == writeregM & regwriteM);
assign forwardbD = (rtD != 0 & rtD == writeregM & regwriteM);

// Forwarding sources to E stage (ALU)
always @(*) begin
    forwardaE = 2'b00;
    forwardbE = 2'b00;
    if (rsE != 0) begin
        if (rsE == writeregM & regwriteM) begin
            forwardaE = 2'b10;
        end else if (rsE == writeregW & regwriteW) begin
            forwardaE = 2'b01;
        end
    end
    if (rtE != 0) begin
        if (rtE == writeregM & regwriteM) begin
            forwardbE = 2'b10;
        end else if (rtE == writeregW & regwriteW) begin
            forwardbE = 2'b01;
        end
    end
end

// Stalls
assign lwstallD = memtoregE & (rtE == rsD | rtE == rtD);
assign branchstallD = (branchD | jrD) &
    (regwriteE & (writeregE == rsD | writeregE == rtD) |
    memtoregM & (writeregM == rsD | writeregM == rtD));
assign stallD = lwstallD | branchstallD | div_stallE;
assign stallF = (~is_exceptM & stallD);

assign stallE = div_stallE;

assign flushD = is_exceptM;
assign flushE = lwstallD | branchstallD | is_exceptM;
assign flushM = is_exceptM | div_stallE;
assign flushW = is_exceptM;

endmodule
