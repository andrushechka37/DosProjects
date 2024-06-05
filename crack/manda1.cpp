#include <SFML/Graphics.hpp>
#include <cmath>
#include <string>

const int MAX_ITERATIONS = 256;
const float RADIUS = 10.0f;
const int WIDTH = 800;
const int HEIGHT = 600;

int get_colour(float x0, float y0) {

    float x = 0.0f;
    float y = 0.0f;

    float xx = 0;
    float yy = 0;

    int iteration = 0;

    while (xx + yy <= RADIUS && iteration < MAX_ITERATIONS) {
        xx = x*x;
        yy = y*y;
        
        float xtemp = xx - yy + x0;
        y = 2*x*y + y0;
        x = xtemp;
        iteration++;
    }

    if (iteration == MAX_ITERATIONS)
        return 0;
    else
        return iteration;
}

int main() {

    sf::RenderWindow window(sf::VideoMode(WIDTH, HEIGHT), "Mandelbrot Set");

    sf::Image image;
    image.create(WIDTH, HEIGHT, sf::Color::Black);

    sf::Texture texture;
    texture.create(WIDTH, HEIGHT);
    sf::Sprite sprite(texture);

    sf::Font font;
    sf::Text fpsText("", font, 20);
    fpsText.setColor(sf::Color::White);
    fpsText.setPosition(10, 10);

    sf::Clock gameClock; // Переименовано из clock в gameClock
    int frames = 0;

    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();
        }

// ---------------------------------------------------------------------

        // Отрисовка Mandelbrot Set
        for (int y = 0; y < HEIGHT; ++y) {
            for (int x = 0; x < WIDTH; ++x) {

                float xx = (float)x / WIDTH * 3.5f - 2.5f;
                float yy = (float)y / HEIGHT * 2.0f - 1.0f;

                int color = get_colour(xx, yy);
                sf::Color sfColor((color * 6) % 256, 0, (color * 10) % 256);
                image.setPixel(x, y, sfColor);
            }
        }
// ---------------------------------------------------------------------

        texture.update(image);

        window.clear();
        window.draw(sprite);
        window.display();
    }

    return 0;
}
