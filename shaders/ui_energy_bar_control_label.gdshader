shader_type canvas_item;
//skew text at 20 degrees, mirroring the -20 degree skew of the meter pips
void vertex() {
    float radians = radians(20);
    VERTEX.x += tan(radians) * VERTEX.y;
}