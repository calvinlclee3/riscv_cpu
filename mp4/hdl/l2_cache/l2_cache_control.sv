/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module l2_cache_control (
	          input clk,
    		  input rst,
		      input logic 	 hit_way1,
		      input logic 	 hit_way0,
		      input logic 	 mem_read,
		      input logic 	 mem_write,
		      input logic    pmem_resp,
			  input logic	 lru,
			  input logic	 dirty1,
			  input logic	 dirty0,
		      output logic 	 load_mem_address_reg,
		      output logic 	 lru_mux,
		      output logic 	 load_lru,
		      output logic 	 mem_resp,
		      output logic [1:0] data_array0_mux,
		      output logic 	 datain0_mux,
		      output logic 	 dirty_mux,
		      output logic 	 load_way0_dirty,
		      output logic 	 load_way1_dirty,
		      output logic [1:0] data_array1_mux,
		      output logic 	 datain1_mux,
		      output logic 	 pmem_read,
		      output logic 	 valid_mux,
		      output logic 	 load_pmem_reg,
		      output logic 	 load_way1_tag,
		      output logic 	 load_way0_tag,
		      output logic 	 load_way1_valid,
		      output logic 	 load_way0_valid,
		      output logic 	 pmem_control,
		      output logic 	 pmem_write
);

   function void set_defaults();

      load_mem_address_reg = 1'b0;
      lru_mux = 1'b0;
      load_lru = 1'b0;
      mem_resp = 1'b0;
      data_array0_mux = 2'b00;
      datain0_mux = 1'b0;
      dirty_mux = 1'b0;
      load_way0_dirty = 1'b0;
      load_way1_dirty = 1'b0;
      data_array1_mux = 2'b00;
      datain1_mux = 1'b0;
      pmem_read = 1'b0;
      valid_mux = 1'b0;
      load_pmem_reg = 1'b0;
      load_way1_tag = 1'b0;
      load_way0_tag = 1'b0;
      load_way0_valid = 1'b0;
      load_way1_valid = 1'b0;
      pmem_control = 1'b0;
      pmem_write = 1'b0;
      
      endfunction


		enum int unsigned {
		  Idle, Cache, Allocate, WriteBack, Reset
	  } state, next_state;


	  always_ff @(posedge clk)
	  begin


		if (rst)
		begin
			state <= Reset;

		end

		else begin
			state <= next_state;
		end

	  end

	always_comb begin //NEXT state assignment
		next_state = state; //default next state is current state

		case (state)
		
		Reset: next_state = Idle;

		Idle: begin 
			if (mem_read | mem_write)
			  begin
				  next_state = Cache; //upon reception of a valid request, access cache
			  end
		end
		
		Cache: begin
			if (hit_way0 | hit_way1)
				begin
					next_state = Idle; //if hit, go back to idle state
				end

				else if ((lru & dirty1) | (~lru & dirty0)) //dirty bit set, need to writeback
				begin
					next_state = WriteBack;
				end

				else if ((lru & ~dirty1) | (~lru & ~dirty0))
				begin
					next_state = Allocate;
				end
		end

		Allocate: begin
			if (pmem_resp == 1'b1)
			begin
				next_state = Cache;
			end
		end

		WriteBack:
		begin

			if (pmem_resp == 1'b1)
			begin
				next_state = Allocate;
			end
		end

		endcase


	end

	


	always_comb begin //control signal assignment

	set_defaults();

	case (state)
		Reset: begin //set all valid bits to 0
			valid_mux = 1'b0;
			load_way0_valid = 1'b1;
			load_way1_valid = 1'b1;
		end

		Idle:;

		Cache: begin
			load_mem_address_reg = 1'b1;

			if (hit_way0 & mem_read)
			begin
				lru_mux = 1'b1;
				load_lru = 1'b1;
				mem_resp = 1'b1;
			end

			if (hit_way1 & mem_read)
			begin
				lru_mux = 1'b0;
				load_lru = 1'b1;
				mem_resp = 1'b1;
			end

			if (hit_way0 & mem_write)
			begin
				data_array0_mux = 2'b01;
				datain0_mux = 1'b0;
				lru_mux = 1'b1;
				load_lru = 1'b1;
				dirty_mux = 1'b1;
				load_way0_dirty = 1'b1;
				mem_resp = 1'b1;
			end

			if (hit_way1 & mem_write)
			begin
				data_array1_mux  = 2'b01;
				datain1_mux = 1'b0;
				lru_mux = 1'b0;
				load_lru = 1'b1;
				dirty_mux = 1'b1;
				load_way1_dirty = 1'b1;
				mem_resp = 1'b1;
			end
		end

		Allocate: begin
			pmem_read = 1'b1;
			valid_mux = 1'b1;
			dirty_mux = 1'b0;
				load_pmem_reg = 1'b1;
				if (lru == 1'b1) 
				begin
					load_way1_tag = 1'b1;
					load_way1_valid = 1'b1;
					load_way1_dirty = 1'b1;
					data_array1_mux = 2'b10;
					datain1_mux = 1'b1;
				end


				else if (lru == 1'b0) begin
					load_way0_tag = 1'b1;
					load_way0_valid = 1'b1;
					load_way0_dirty = 1'b1;
					data_array0_mux = 2'b10;
					datain0_mux = 1'b1;
				end


		end

		WriteBack: begin
			pmem_control = 1'b1;
			pmem_write = 1'b1;
		end

	endcase

	end

	

endmodule : l2_cache_control
