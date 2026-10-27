module MyDesign(
  input  wire reset_n, clk, dut_valid,
  output reg  dut_ready,
  output wire input_sram_write_enable,
  output wire [31:0]  input_sram_write_address,
  output wire [127:0] input_sram_write_data,
  output reg [31:0]  input_sram_read_address,
  input  wire [127:0] input_sram_read_data,
  output reg output_sram_write_enable,
  output reg [31:0]  output_sram_write_address,
  output reg [127:0] output_sram_write_data,
  output wire [31:0]  output_sram_read_address,
  input  wire [127:0] output_sram_read_data,
  output reg scratchpad_sram_write_enable,
  output reg [31:0]  scratchpad_sram_write_address,
  output reg [127:0] scratchpad_sram_write_data,
  output reg [31:0]  scratchpad_sram_read_address,
  input  wire [127:0] scratchpad_sram_read_data,
  output wire gates_sram_write_enable,
  output wire [31:0]  gates_sram_write_address,
  output wire [127:0] gates_sram_write_data,
  output reg [31:0]  gates_sram_read_address,
  input  wire [127:0] gates_sram_read_data);

  assign {input_sram_write_enable, input_sram_write_address, input_sram_write_data, gates_sram_write_enable, gates_sram_write_address, gates_sram_write_data, output_sram_read_address }= 0;


  reg [127:0] vec [0:63];      
  reg [127:0] g;               
  reg [63:0]  acc_r, acc_i;    

  reg [31:0] dim, matrices, m, row, col, i, gate_addr;        

  wire [63:0] gr = g[127:64];          
  wire [63:0] gi = g[63:0];           
  wire [63:0] vr = vec[col][127:64];   
  wire [63:0] vi = vec[col][63:0];     

  localparam [4:0]
    IDLE = 0,
    HDR_WAIT = 1,  
	HDR_READ = 2,                    
    LOAD_ADDR = 3,  
  	LOAD_WAIT = 4,  
  	LOAD_SAVE = 5,   
    GATE_ADDR = 6,  
  	GATE_WAIT = 7,  
  	GATE_SAVE = 8,    
    MUL1 = 9,  
  	MUL2 = 10,                   
    MUL3 = 11, 
  	MUL4 = 12,                   
    WRITE_ROW = 13,                                    
    COPY_OUT = 14,                                   
    DONE = 15;
  reg [4:0] state;

  reg  [63:0] a, b, c;
  wire [63:0] result;
  wire invalid, overflow, underflow, inexact;   
  fp64_fma U1 (.a(a), .b(b), .c(c), .rnd(3'b000), .result(result),
               .invalid(invalid), .overflow(overflow),
               .underflow(underflow), .inexact(inexact));

  always @(*) begin
    a = 64'd0;  b = 64'd0;  c = 64'd0;
    case (state)
      MUL1: 
      	begin 
        a = gr;                    
        b = vr;  
        c = acc_r; 
      	end  
      MUL2: 
        begin 
          a = {~gi[63], gi[62:0]};   
          b = vi;  
          c = acc_r; 
        end  
      MUL3: 
        begin 
          a = gr;                    
          b = vi;  
          c = acc_i; 
        end  
      MUL4: 
        begin 
          a = gi;                    
          b = vr;  
          c = acc_i; 
        end  
      default: ;
    endcase
  end

  always @(posedge clk) begin
    if (!reset_n) 
	 begin
      state     <= IDLE;
      dut_ready <= 1'b1;
      input_sram_read_address <= 0;
      gates_sram_read_address <= 0;
      scratchpad_sram_read_address <= 0;
      output_sram_write_enable <= 0;
      output_sram_write_address <= 0;
      output_sram_write_data <= 0;
      scratchpad_sram_write_enable <= 0;
      scratchpad_sram_write_address<= 0;
      scratchpad_sram_write_data <= 0;
      g <= 0;  
	  acc_r <= 0;  
	  acc_i <= 0;
      dim <= 0;  
	  matrices <= 0;  
	  m <= 0;  
	  row <= 0;  
	  col <= 0;  
	  i <= 0;  
	  gate_addr <= 0;
     end 
	else 
	 begin
      output_sram_write_enable <= 0;
      scratchpad_sram_write_enable <= 0;

      case (state)

        IDLE: if (dut_valid) begin
          dut_ready <= 0;                    
          input_sram_read_address <= 0;      
          m <= 0;  
		  gate_addr <= 0;  
	  	  acc_r <= 0;  
          acc_i <= 0;
          state <= HDR_WAIT;
        end

        HDR_WAIT: state <= HDR_READ;         
       
        HDR_READ: begin
          if (input_sram_read_data[127:64] > 6)
            state <= DONE;                  
          else begin
            dim      <= 32'd1 << input_sram_read_data[69:64];
            matrices <= input_sram_read_data[31:0];
            i        <= 0;
            state    <= LOAD_ADDR;
          end
        end
        
        LOAD_ADDR: begin
          if (m == 0) 
				input_sram_read_address <= i + 1;
          else        
				scratchpad_sram_read_address <= i;
          state <= LOAD_WAIT;
        end
        
        LOAD_WAIT: state <= LOAD_SAVE;
        
        LOAD_SAVE: begin
         vec[i] <= (m == 0) ? input_sram_read_data : scratchpad_sram_read_data;
          if (i + 1 == dim) begin            
            row <= 0;  col <= 0;
            state <= (matrices == 0) ? COPY_OUT : GATE_ADDR;
          end 
          else 
           begin
            i <= i + 1;
            state <= LOAD_ADDR;
           end
        end

        COPY_OUT: begin
          output_sram_write_enable  <= 1;
          output_sram_write_address <= row;
          output_sram_write_data    <= vec[row];
          if (row + 1 == dim) 
            state <= DONE;
          else                
            row <= row + 1;
        end

        GATE_ADDR: begin
          gates_sram_read_address <= gate_addr;
          state <= GATE_WAIT;
        end
        
        GATE_WAIT: state <= GATE_SAVE;
        GATE_SAVE: begin
          g <= gates_sram_read_data;
          gate_addr <= gate_addr + 1;
          state <= MUL1;
        end

        MUL1: begin 
          acc_r <= result;  
          state <= MUL2; 
        end
        MUL2: begin 
          acc_r <= result;  
          state <= MUL3; 
        end
        MUL3: begin 
          acc_i <= result;  
          state <= MUL4; 
        end
        MUL4: begin
          acc_i <= result;
          if (col + 1 == dim) state <= WRITE_ROW;   
          else begin
            col   <= col + 1;
            state <= GATE_ADDR;                     
          end
        end
        
        WRITE_ROW: begin
          if (m + 1 == matrices) begin
            output_sram_write_enable  <= 1;
            output_sram_write_address <= row;
            output_sram_write_data    <= {acc_r, acc_i};
          end 
          else begin
            scratchpad_sram_write_enable  <= 1;
            scratchpad_sram_write_address <= row;
            scratchpad_sram_write_data    <= {acc_r, acc_i};
          end
          
          acc_r <= 0;  
          acc_i <= 0;  
          col <= 0;      

          if (row + 1 < dim) begin                  
            row   <= row + 1;
            state <= GATE_ADDR;
          end 
          else if (m + 1 < matrices) begin     
            m     <= m + 1;
            i     <= 0;
            state <= LOAD_ADDR;
          end 
          else
            state <= DONE;                         
        end
     
        DONE: begin
          dut_ready <= 1;
          state     <= IDLE;
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
