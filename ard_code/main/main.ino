#define INSTRUCTION_MEMORY_SIZE 256 // Define the size of the instruction memory
#define DATA_MEMORY_SIZE 256

#define opcode_mask 0x7  // Mask to isolate the instruction type


uint16_t instructionMemory[INSTRUCTION_MEMORY_SIZE]; // Allocate an instruction memory of uint16_t
uint16_t dataMemory[DATA_MEMORY_SIZE]; // Allocate an instruction memory of uint16_t

int in_bus_pins[8] = {0, 1, 2, 3, 4, 5, 6, 7};

int out_bus_pins[8] = {16, 17, 18, 19, 20, 21, 22, 26 };

int ard_data_ready = 12;
int ard_receive_ready = 13;

int bus_pc = 8;
int bus_mar = 9;
int bus_mdr = 10;
int halt = 11;
int clk = 14; 
int rst = 15;

uint16_t pc = 0;
uint16_t address = 0;
uint16_t addr;
int16_t data = 0;

enum opcode_t {
  R_TYPE = 0b000,
  I_TYPE = 0b001,
  B_TYPE = 0b010,
  J_TYPE = 0b011,
  M_TYPE = 0b100,
  NOP_TYPE = 0b101,
  SYS_END = 0b110
};

enum instruction_t {
  SUB = 0b000,
  ADD = 0b001,
  SW = 0b100,
  LW = 0b010
};




void setup() {
  // put your setup code here, to run once:

  for(int i = 0; i < 8; i++) {
    pinMode(out_bus_pins[i], OUTPUT);
    pinMode(in_bus_pins[i], INPUT); 
  }

  pinMode(ard_data_ready, OUTPUT);
  pinMode(ard_receive_ready, OUTPUT);
  pinMode(clk, OUTPUT);
  pinMode(rst, OUTPUT);

  pinMode(bus_pc, INPUT);
  pinMode(bus_mar, INPUT);
  pinMode(bus_mdr, INPUT);
  pinMode(halt,   INPUT);
  pinMode(LED_BUILTIN, OUTPUT);

  addr = 4;
  int16_t a = 5;
  int16_t b = 6;
  int16_t result = a - b;
  instructionMemory[0] = (SUB << 11) | (1 << 8) | (0 << 5) | (0 << 2) | I_TYPE;
  instructionMemory[1] = a;
  instructionMemory[2] = (SUB << 11) | (2 << 8) | (0 << 5) | (0 << 2) | I_TYPE;
  instructionMemory[3] = b;
  instructionMemory[4] = (SUB << 11) | (3 << 8) | (1 << 5) | (2 << 2) | R_TYPE;
  instructionMemory[5] = (SW << 11) | (4 << 8) | (3 << 5) | (0 << 2) | M_TYPE;
  instructionMemory[6] = addr;
  instructionMemory[7] = (LW << 11) | (2 << 8) | (0 << 5) | (0 << 2) | M_TYPE;
  instructionMemory[8] = addr;
  instructionMemory[9] = SYS_END;
  

  Serial.begin(9600); // Start the serial communication might be wrong
  Serial.println(3);

}

void loop() {

  //get values
    digitalWrite(rst, LOW);
    digitalWrite(ard_receive_ready, LOW);
    digitalWrite(ard_data_ready, LOW);
    posedge_clk();
    digitalWrite(rst, HIGH);
    posedge_clk();
    digitalWrite(rst, LOW);
    digitalWrite(ard_receive_ready, HIGH);
    posedge_clk();
    posedge_clk();
    posedge_clk();
    while(digitalRead(halt) != HIGH) {
      if(digitalRead(bus_pc) == HIGH){
        pc = readBus();
        uint16_t instruction = instructionMemory[pc];  // Get the current instruction
        opcode_t instructionType = (opcode_t)(instruction & opcode_mask);
        digitalWrite(ard_receive_ready, LOW);
        digitalWrite(ard_data_ready, HIGH);
        writeBus(instructionMemory[pc]);
        if(instructionType == I_TYPE || instructionType == M_TYPE) {
          writeBus(instructionMemory[pc+1]);
          digitalWrite(ard_data_ready, LOW);
        } else {
          digitalWrite(ard_data_ready, LOW);
        }
        digitalWrite(ard_receive_ready, HIGH);
        posedge_clk();
      } else if(digitalRead(bus_mar) == HIGH){
        address = readBus();
        if(digitalRead(bus_mdr) != HIGH) {
          digitalWrite(ard_receive_ready, LOW);
          digitalWrite(ard_data_ready, HIGH);
          writeBus(dataMemory[address]);
          digitalWrite(ard_receive_ready, HIGH);
          digitalWrite(ard_data_ready, LOW);
          posedge_clk();
        } else {
          data = readBus();
          dataMemory[address] = data;
          digitalWrite(ard_receive_ready, HIGH);
          digitalWrite(ard_data_ready, LOW);
          posedge_clk();
        }
      } else {
        posedge_clk();
      }
    }
    Serial.println(dataMemory[addr]);
}

void posedge_clk(){
  digitalWrite(clk, HIGH);
  delay(0.0005);
  digitalWrite(clk, LOW);
  delay(0.0005);
}

uint16_t readBus() {
  uint16_t value = 0;  // Initialize the value

  // Read the first 8 bits from the bus
  for (int i = 0; i < 8; i++) {
    value |= digitalRead(in_bus_pins[i]) << i;
  }
  posedge_clk();  // Call posedge_clk() function

  // Read the second 8 bits from the bus
  for (int i = 8; i < 16; i++) {
    value |= digitalRead(in_bus_pins[i-8]) << i;
  }
  posedge_clk();  // Call posedge_clk() function

  return value;  // Return the 16-bit value
}

void writeBus(uint16_t value) {
  // Write the first 8 bits of the value to the bus
  for (int i = 0; i < 8; i++) {
    digitalWrite(out_bus_pins[i], bitRead(value, i));
  }
  posedge_clk();  // Call posedge_clk() function

  // Write the second 8 bits of the value to the bus
  for (int i = 8; i < 16; i++) {
    digitalWrite(out_bus_pins[i-8], bitRead(value, i));
  }
  posedge_clk();  // Call posedge_clk() function
}
