module InstructionManagerUnit import Types::*; (
    input logic clk,
    input logic rst,

    AvalonMmRead.Host instruction_manager,

    input uint32_t pc,
    input bit fetch_next_instruction,

    output bit ready,
    output uint32_t ir,
);
    enum int { IDLE, PUT_DATA_ON_BUS, WAITING_FOR_RESPONSE } state;

    assign instruction_manager.read = state == PUT_DATA_ON_BUS;
    assign instruction_manager.byteenable = 4'b1111;
    assign ready = state == IDLE;

    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
        end else begin
            unique case (state)
                IDLE: if(fetch_next_instruction) begin
                    instruction_manager.address <= pc;
                    state <= PUT_DATA_ON_BUS;
                end
            
                PUT_DATA_ON_BUS: if(instruction_manager.readdatavalid) begin
                    ir <= instruction_manager.agent_to_host;
                    state <= IDLE;
                end else if(instruction_manager.waitrequest) begin
                    state <= PUT_DATA_ON_BUS;
                end else begin
                    state <= WAITING_FOR_RESPONSE;
                end
                
                WAITING_FOR_RESPONSE: if(instruction_manager.readdatavalid) begin
                    ir <= instruction_manager.agent_to_host;
                    state <= IDLE;
                end
            endcase
        end
    end

    task automatic simulate_ready(input uint32_t in);
        ir <= in;
        state <= IDLE;
    endtask
endmodule