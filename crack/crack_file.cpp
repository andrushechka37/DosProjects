#include "Graphics.hpp"

void crack_file(FILE * file) {

    if (file == NULL) {
        printf("null ptr file");
        return;
    }

    char nope_buffer[] = {0x90, 0x90};                  // nop code is 90

    int offset = 38;                                    // 2 lines (length is 16) + 6 hex numbers + one byte of offset
    fseek(file, offset, 0);
    fwrite(nope_buffer, sizeof(char), 2, file);

    return;
}

int main()
{

    FILE * program_file = fopen("CRE.COM", "r+b");

    crack_file(program_file);

    fclose(program_file);

    sf::RenderWindow window(sf::VideoMode(2000, 2000), "CRAAAAAACK!!!!!!");
    sf::CircleShape shape(100.f);
    shape.setFillColor(sf::Color::Blue);

    sf::Texture texture;
    texture.loadFromFile("crack.png");
    sf::Sprite sprite(texture);

    while (window.isOpen())
    {
        sf::Event event;
        while (window.pollEvent(event))
        {
            if (event.type == sf::Event::Closed)
                window.close();
        }

        window.clear();
        window.draw(sprite);
        window.display();
    }

    return 0;
}